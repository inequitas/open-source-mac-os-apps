# BotDeck

A native SwiftUI iOS client for Discord that connects **as a bot** using
Discord's official [Gateway](https://discord.com/developers/docs/topics/gateway)
(WebSocket) and [REST API v10](https://discord.com/developers/docs/reference).

It's a lightweight "secondary client" for reading and posting in servers where
your bot is a member — useful as a companion deck, moderation tool, or a
minimal reader you fully control.

> ⚠️ **This is a bot client, not a personal-account client.** It authenticates
> only with a **bot token**. Logging into a personal Discord account through an
> unofficial client (a "self-bot" / user token) **violates Discord's Terms of
> Service** and can get your account banned. BotDeck does not do that and should
> not be modified to.

## Features (v0.1)

- 🔐 Bot token stored in the iOS **Keychain** (never in plain files/UserDefaults)
- 🌐 **Gateway** connection: HELLO → IDENTIFY, heartbeats, READY, live
  `MESSAGE_CREATE` events
- 🗂 Browse your bot's **servers → text channels**
- 💬 Read recent messages and **send** messages
- 🔄 Live updates in the open channel

## Requirements

- macOS with **Xcode 15+** (iOS 16.0 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- A Discord bot (see setup below)

## Setup

1. Go to <https://discord.com/developers/applications>, create an application,
   and add a **Bot**.
2. Under the bot settings, enable the **Message Content Intent** (privileged).
3. Copy the **bot token**.
4. Invite the bot to a server (OAuth2 → URL Generator → `bot` scope, with the
   permissions you want, e.g. *View Channels*, *Send Messages*, *Read Message
   History*).

## Build & run

```bash
cd DiscordClient
xcodegen generate      # produces BotDeck.xcodeproj from project.yml
open BotDeck.xcodeproj # then select a simulator / device and Run
```

On first launch, paste your bot token. It's validated via `GET /users/@me`,
saved to the Keychain, and the Gateway connection opens.

## Project layout

```
DiscordClient/
├── project.yml                 # XcodeGen project definition
└── Sources/
    ├── BotDeckApp.swift         # App entry + root routing
    ├── Models/                  # Codable Discord objects
    ├── Networking/
    │   ├── DiscordREST.swift    # REST API v10 wrapper
    │   └── DiscordGateway.swift # WebSocket gateway client
    ├── Store/
    │   ├── AppState.swift       # Observable app state
    │   └── KeychainStore.swift  # Secure token storage
    └── Views/                   # SwiftUI screens
```

## Roadmap / not yet implemented

- Gateway RESUME (currently reconnects with a fresh IDENTIFY)
- Threads, DMs, embeds, attachments, reactions, and Markdown rendering
- Pagination / infinite scroll of message history
- Multiple bot accounts
- Rate-limit handling with retry-after

Contributions welcome — keep it bot-only and ToS-compliant.
