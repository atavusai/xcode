import Foundation

/// A conversation session that maintains message history for context.
///
/// Create a session via ``AtavusClient/createSession()``, then use
/// ``send(_:)`` and ``stream(_:)`` to chat while preserving history.
public final class Session: @unchecked Sendable {
    private let client: AtavusClient
    private let sessionId: String
    private var messages: [Message]
    private let assistantId: String

    /// The unique identifier for this session.
    public var id: String { sessionId }

    /// The message history for this session.
    public var history: [Message] { messages }

    init(client: AtavusClient, sessionId: String, assistantId: String) {
        self.client = client
        self.sessionId = sessionId
        self.assistantId = assistantId
        self.messages = []
    }

    /// Sends a message and returns the full response. The message and response
    /// are automatically appended to the conversation history.
    /// - Parameter text: The message text.
    /// - Returns: The assistant's response.
    @discardableResult
    public func send(_ text: String) async throws -> AssistantResponse {
        let userMessage = Message(role: "user", content: text, timestamp: Date())
        messages.append(userMessage)

        let response = try await client.sendMessage(text, sessionId: sessionId)

        let assistantMessage = Message(role: "assistant", content: response.text, timestamp: Date())
        messages.append(assistantMessage)

        return response
    }

    /// Sends a message and streams the response. The message is appended to
    /// history immediately; the response is appended when streaming completes.
    /// - Parameter text: The message text.
    /// - Returns: An async throwing stream of response chunks.
    public func stream(_ text: String) -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let userMessage = Message(role: "user", content: text, timestamp: Date())
                self.messages.append(userMessage)

                var fullText = ""
                do {
                    for try await chunk in try await client.streamMessage(text, sessionId: sessionId) {
                        fullText += chunk.text
                        continuation.yield(chunk)
                    }
                    let assistantMessage = Message(
                        role: "assistant",
                        content: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                        timestamp: Date()
                    )
                    self.messages.append(assistantMessage)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Clears the conversation history for this session.
    public func clearHistory() {
        messages.removeAll()
    }
}
