import SwiftUI

/// A floating chat button that opens the full Atavus AI chat view.
///
/// ```swift
/// ContentView()
///     .overlay(alignment: .bottomTrailing) {
///         AtavusChatButton(client: client)
///     }
/// ```
public struct AtavusChatButton: View {
    private let client: AtavusClient
    private let theme: AtavusChatTheme

    @State private var showChat = false
    @State private var unreadCount = 0

    public init(
        client: AtavusClient,
        theme: AtavusChatTheme = .default
    ) {
        self.client = client
        self.theme = theme
    }

    public var body: some View {
        Button(action: { showChat = true }) {
            ZStack {
                Circle()
                    .fill(theme.primaryColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: theme.primaryColor.opacity(0.4), radius: 12, x: 0, y: 4)

                Image(systemName: "message.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                if unreadCount > 0 {
                    Circle()
                        .fill(theme.secondaryColor)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Text("\(unreadCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 18, y: -18)
                }
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView(client: client, theme: theme)
        }
    }
}

/// The full chat view presented when the chat button is tapped.
public struct ChatView: View {
    private let client: AtavusClient
    private let theme: AtavusChatTheme

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var session: Session?
    @Environment(\.dismiss) private var dismiss

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }

    public init(client: AtavusClient, theme: AtavusChatTheme = .default) {
        self.client = client
        self.theme = theme
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(theme.primaryColor)
                Text("Atavus AI")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(theme.backgroundColor)

            Divider().opacity(0.1)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundColor(theme.primaryColor.opacity(0.5))
                                Text("Ask me anything!")
                                    .font(theme.font)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 60)
                        }

                        ForEach(messages) { msg in
                            ChatBubble(text: msg.text, isUser: msg.isUser, theme: theme)
                                .id(msg.id)
                        }

                        if isLoading {
                            HStack {
                                ThinkingIndicator()
                                Spacer()
                            }
                            .id("loading")
                        }

                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .background(theme.backgroundColor)
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: isLoading) { loading in
                    if loading {
                        withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                    }
                }
            }

            // Input
            VStack(spacing: 0) {
                Divider().opacity(0.1)
                HStack(spacing: 8) {
                    TextField("Type a message...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(theme.font)
                        .foregroundColor(theme.textColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(theme.inputBackgroundColor)
                        .cornerRadius(22)
                        .disabled(isLoading)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(
                                inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                                    ? .gray.opacity(0.3)
                                    : theme.primaryColor
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
                .padding()
            }
            .background(theme.backgroundColor)
        }
        .background(theme.backgroundColor)
        .onAppear {
            initSession()
        }
    }

    private func initSession() {
        Task {
            do {
                let newSession = try await client.createSession()
                await MainActor.run { session = newSession }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to connect: \(error.localizedDescription)"
                }
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        errorMessage = nil

        let userMsg = ChatMessage(text: text, isUser: true)
        messages.append(userMsg)

        isLoading = true

        Task {
            do {
                if let session = session {
                    let response = try await session.send(text)
                    await MainActor.run {
                        messages.append(ChatMessage(text: response.text, isUser: false))
                        isLoading = false
                    }
                } else {
                    let response = try await client.sendMessage(text)
                    await MainActor.run {
                        messages.append(ChatMessage(text: response.text, isUser: false))
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
