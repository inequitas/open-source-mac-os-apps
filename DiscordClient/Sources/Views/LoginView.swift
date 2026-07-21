import SwiftUI

struct LoginView: View {
    @EnvironmentObject var state: AppState
    @State private var token = ""
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Bot token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Discord Bot Token")
                } footer: {
                    Text("Create a bot at discord.com/developers, enable the Message Content intent, and paste its token here. The token is stored in the iOS Keychain. This app connects only as a bot — never with a personal-account token.")
                }

                if let error = state.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button {
                        Task {
                            isWorking = true
                            await state.authenticate(token: token)
                            isWorking = false
                        }
                    } label: {
                        if isWorking {
                            ProgressView()
                        } else {
                            Text("Connect")
                        }
                    }
                    .disabled(token.isEmpty || isWorking)
                }
            }
            .navigationTitle("BotDeck")
        }
    }
}
