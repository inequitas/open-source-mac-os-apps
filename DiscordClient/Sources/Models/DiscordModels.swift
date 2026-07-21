import Foundation

// MARK: - REST / Gateway payload models
// A minimal subset of Discord's object model — enough for a bot-based
// read/send client. Extend as needed.

struct DiscordUser: Codable, Identifiable, Hashable {
    let id: String
    let username: String
    let globalName: String?
    let avatar: String?
    let bot: Bool?

    enum CodingKeys: String, CodingKey {
        case id, username, avatar, bot
        case globalName = "global_name"
    }

    var displayName: String { globalName ?? username }
}

struct Guild: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String?

    var iconURL: URL? {
        guard let icon else { return nil }
        return URL(string: "https://cdn.discordapp.com/icons/\(id)/\(icon).png")
    }
}

struct Channel: Codable, Identifiable, Hashable {
    let id: String
    let type: Int
    let name: String?
    let guildId: String?
    let position: Int?
    let parentId: String?

    enum CodingKeys: String, CodingKey {
        case id, type, name, position
        case guildId = "guild_id"
        case parentId = "parent_id"
    }

    // Text (0), Announcement (5), Thread (10, 11, 12) are messageable here.
    var isTextChannel: Bool { [0, 5].contains(type) }
}

struct Message: Codable, Identifiable, Hashable {
    let id: String
    let channelId: String
    let content: String
    let author: DiscordUser
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id, content, author, timestamp
        case channelId = "channel_id"
    }

    var date: Date {
        ISO8601DateFormatter.discord.date(from: timestamp) ?? Date()
    }
}

extension ISO8601DateFormatter {
    static let discord: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
