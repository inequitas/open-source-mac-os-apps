import SwiftUI

struct GuildListView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        NavigationStack {
            List(state.guilds) { guild in
                NavigationLink(value: guild) {
                    HStack(spacing: 12) {
                        GuildIcon(guild: guild)
                        Text(guild.name)
                    }
                }
            }
            .navigationTitle("Servers")
            .navigationDestination(for: Guild.self) { guild in
                ChannelListView(guild: guild)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let user = state.currentUser {
                            Text("Signed in as \(user.displayName)")
                        }
                        Button("Sign Out", role: .destructive) { state.signOut() }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
    }
}

struct GuildIcon: View {
    let guild: Guild

    var body: some View {
        AsyncImage(url: guild.iconURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack {
                Circle().fill(.secondary.opacity(0.2))
                Text(String(guild.name.prefix(1)))
                    .font(.headline)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}
