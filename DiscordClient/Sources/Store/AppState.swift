import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: DiscordUser?
    @Published var guilds: [Guild] = []
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    private(set) var rest: DiscordREST?
    private(set) var gateway: DiscordGateway?

    init() {
        if let token = KeychainStore.loadToken() {
            Task { await authenticate(token: token, persist: false) }
        }
    }

    /// Validates the token via GET /users/@me, then stores it and opens the Gateway.
    func authenticate(token: String, persist: Bool = true) async {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let rest = DiscordREST(token: trimmed)
        do {
            let user = try await rest.currentUser()
            let guilds = try await rest.guilds()
            self.rest = rest
            self.currentUser = user
            self.guilds = guilds
            self.isAuthenticated = true
            self.errorMessage = nil
            if persist { KeychainStore.saveToken(trimmed) }
            startGateway(token: trimmed)
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
        }
    }

    private func startGateway(token: String) {
        let gateway = DiscordGateway(token: token)
        self.gateway = gateway
        gateway.connect()
    }

    func signOut() {
        KeychainStore.deleteToken()
        gateway?.disconnect()
        gateway = nil
        rest = nil
        currentUser = nil
        guilds = []
        isAuthenticated = false
    }
}
