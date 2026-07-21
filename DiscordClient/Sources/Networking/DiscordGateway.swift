import Foundation

/// Discord Gateway (v10) client over WebSocket.
///
/// Implements the core lifecycle: HELLO -> IDENTIFY, periodic heartbeats,
/// and dispatch of READY / MESSAGE_CREATE events. Resume/reconnect is
/// intentionally simplified (a fresh IDENTIFY on drop) for this first pass.
@MainActor
final class DiscordGateway: NSObject, ObservableObject {
    enum Status: Equatable { case disconnected, connecting, ready }

    @Published private(set) var status: Status = .disconnected

    /// Called on the main actor when a MESSAGE_CREATE arrives.
    var onMessageCreate: ((Message) -> Void)?

    private let token: String
    private let intents: Int
    private var task: URLSessionWebSocketTask?
    private var heartbeatTask: Task<Void, Never>?
    private var lastSequence: Int?
    private var explicitlyClosed = false

    /// GUILDS (1<<0) + GUILD_MESSAGES (1<<9) + MESSAGE_CONTENT (1<<15).
    /// MESSAGE_CONTENT is a privileged intent — enable it in the Developer Portal.
    init(token: String, intents: Int = (1 << 0) | (1 << 9) | (1 << 15)) {
        self.token = token
        self.intents = intents
    }

    func connect() {
        explicitlyClosed = false
        status = .connecting
        let url = URL(string: "wss://gateway.discord.gg/?v=10&encoding=json")!
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        receive()
    }

    func disconnect() {
        explicitlyClosed = true
        heartbeatTask?.cancel()
        heartbeatTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        status = .disconnected
    }

    // MARK: - Receive loop

    private func receive() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message):
                if case let .string(text) = message {
                    Task { await self.handle(text: text) }
                } else if case let .data(data) = message,
                          let text = String(data: data, encoding: .utf8) {
                    Task { await self.handle(text: text) }
                }
                self.receive()
            case .failure:
                Task { await self.handleDrop() }
            }
        }
    }

    private func handleDrop() async {
        heartbeatTask?.cancel()
        status = .disconnected
        if !explicitlyClosed {
            // Basic reconnect with a short delay.
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            connect()
        }
    }

    // MARK: - Payload handling

    private struct GatewayPayload: Decodable {
        let op: Int
        let s: Int?
        let t: String?
    }

    private func handle(text: String) async {
        guard let data = text.data(using: .utf8),
              let payload = try? JSONDecoder().decode(GatewayPayload.self, from: data) else { return }

        if let seq = payload.s { lastSequence = seq }

        switch payload.op {
        case 10: // HELLO
            let interval = extractHeartbeatInterval(from: data) ?? 41_250
            startHeartbeat(intervalMillis: interval)
            sendIdentify()
        case 11: // HEARTBEAT ACK
            break
        case 0: // DISPATCH
            handleDispatch(type: payload.t, raw: data)
        default:
            break
        }
    }

    private func handleDispatch(type: String?, raw: Data) {
        switch type {
        case "READY":
            status = .ready
        case "MESSAGE_CREATE":
            if let message = decodeMessage(from: raw) {
                onMessageCreate?(message)
            }
        default:
            break
        }
    }

    // MARK: - Sending

    private func sendIdentify() {
        let identify: [String: Any] = [
            "op": 2,
            "d": [
                "token": token,
                "intents": intents,
                "properties": [
                    "os": "iOS",
                    "browser": "BotDeck",
                    "device": "BotDeck",
                ],
            ],
        ]
        send(json: identify)
    }

    private func startHeartbeat(intervalMillis: Int) {
        heartbeatTask?.cancel()
        let interval = UInt64(intervalMillis) * 1_000_000
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval)
                guard let self, !Task.isCancelled else { return }
                await self.sendHeartbeat()
            }
        }
    }

    private func sendHeartbeat() {
        send(json: ["op": 1, "d": lastSequence as Any])
    }

    private func send(json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let text = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(text)) { _ in }
    }

    // MARK: - Decoding helpers

    private func extractHeartbeatInterval(from data: Data) -> Int? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let d = obj["d"] as? [String: Any],
              let interval = d["heartbeat_interval"] as? Int else { return nil }
        return interval
    }

    private func decodeMessage(from data: Data) -> Message? {
        struct Envelope: Decodable { let d: Message }
        return try? JSONDecoder().decode(Envelope.self, from: data).d
    }
}
