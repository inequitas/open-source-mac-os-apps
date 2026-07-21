import Foundation

/// Thin async wrapper over the Discord REST API v10 for bot tokens.
struct DiscordREST {
    enum RESTError: LocalizedError {
        case http(Int, String)
        case badResponse

        var errorDescription: String? {
            switch self {
            case let .http(code, body): return "HTTP \(code): \(body)"
            case .badResponse: return "Unexpected response from Discord."
            }
        }
    }

    private let base = URL(string: "https://discord.com/api/v10")!
    private let token: String

    init(token: String) { self.token = token }

    private func request(_ path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("Bot \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("BotDeck/0.1 (iOS)", forHTTPHeaderField: "User-Agent")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw RESTError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw RESTError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    func currentUser() async throws -> DiscordUser {
        let data = try await request("users/@me")
        return try Self.decoder.decode(DiscordUser.self, from: data)
    }

    func guilds() async throws -> [Guild] {
        let data = try await request("users/@me/guilds")
        return try Self.decoder.decode([Guild].self, from: data)
    }

    func channels(guildId: String) async throws -> [Channel] {
        let data = try await request("guilds/\(guildId)/channels")
        return try Self.decoder.decode([Channel].self, from: data)
    }

    func messages(channelId: String, limit: Int = 50) async throws -> [Message] {
        let data = try await request("channels/\(channelId)/messages?limit=\(limit)")
        // Discord returns newest-first; reverse for chronological display.
        return try Self.decoder.decode([Message].self, from: data).reversed()
    }

    @discardableResult
    func sendMessage(channelId: String, content: String) async throws -> Message {
        let payload = try JSONSerialization.data(withJSONObject: ["content": content])
        let data = try await request("channels/\(channelId)/messages", method: "POST", body: payload)
        return try Self.decoder.decode(Message.self, from: data)
    }
}
