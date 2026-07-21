import SwiftUI

struct ChannelListView: View {
    @EnvironmentObject var state: AppState
    let guild: Guild

    @State private var channels: [Channel] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if let error {
                Text(error).foregroundStyle(.red)
            } else {
                ForEach(textChannels) { channel in
                    NavigationLink(value: channel) {
                        Label(channel.name ?? "channel", systemImage: "number")
                    }
                }
            }
        }
        .navigationTitle(guild.name)
        .navigationDestination(for: Channel.self) { channel in
            MessagesView(channel: channel)
        }
        .task { await load() }
    }

    private var textChannels: [Channel] {
        channels
            .filter { $0.isTextChannel }
            .sorted { ($0.position ?? 0) < ($1.position ?? 0) }
    }

    private func load() async {
        guard let rest = state.rest else { return }
        do {
            channels = try await rest.channels(guildId: guild.id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
