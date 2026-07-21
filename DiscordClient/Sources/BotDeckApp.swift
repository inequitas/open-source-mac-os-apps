import SwiftUI

@main
struct BotDeckApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        if state.isAuthenticated {
            GuildListView()
        } else {
            LoginView()
        }
    }
}
