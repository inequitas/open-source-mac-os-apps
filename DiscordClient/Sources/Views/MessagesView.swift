import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var state: AppState
    let channel: Channel

    @State private var messages: [Message] = []
    @State private var draft = ""
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            MessageRow(message: message).id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if let error {
                Text(error).foregroundStyle(.red).font(.footnote).padding(.horizontal)
            }

            composer
        }
        .navigationTitle("#\(channel.name ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onAppear { subscribeToLiveMessages() }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Message #\(channel.name ?? "")", text: $draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await send() }
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    private func load() async {
        guard let rest = state.rest else { return }
        do {
            messages = try await rest.messages(channelId: channel.id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func send() async {
        guard let rest = state.rest else { return }
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        draft = ""
        do {
            let sent = try await rest.sendMessage(channelId: channel.id, content: content)
            // Live gateway may also echo this; guard against duplicates.
            if !messages.contains(where: { $0.id == sent.id }) {
                messages.append(sent)
            }
        } catch {
            self.error = error.localizedDescription
            draft = content
        }
    }

    private func subscribeToLiveMessages() {
        state.gateway?.onMessageCreate = { message in
            guard message.channelId == channel.id else { return }
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        }
    }
}

struct MessageRow: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(message.author.displayName)
                    .font(.subheadline).bold()
                Text(message.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(message.content)
                .font(.body)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
