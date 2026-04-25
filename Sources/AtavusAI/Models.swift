import Foundation

// MARK: - API Response Models

/// A message in a conversation.
public struct Message: Codable, Sendable {
    public let role: String
    public let content: String
    public let timestamp: Date?

    public init(role: String, content: String, timestamp: Date? = nil) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

/// Response from the Atavus AI API.
public struct AssistantResponse: Codable, Sendable {
    public let text: String
    public let sessionId: String?
    public let finishReason: String?
    public let usage: TokenUsage?

    enum CodingKeys: String, CodingKey {
        case text = "response"
        case sessionId = "session_id"
        case finishReason = "finish_reason"
        case usage
    }
}

/// Token usage information.
public struct TokenUsage: Codable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

/// A chunk of a streaming response.
public struct StreamChunk: Codable, Sendable {
    public let text: String
    public let sessionId: String?
    public let finishReason: String?
    public let error: String?

    enum CodingKeys: String, CodingKey {
        case text
        case sessionId = "session_id"
        case finishReason = "finish_reason"
        case error
    }
}

/// A conversation session with history context.
public struct ChatSessionData: Codable, Sendable {
    public let id: String
    public let assistantId: String
    public let messages: [Message]
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case assistantId = "assistant_id"
        case messages
        case createdAt = "created_at"
    }
}

/// Chat request body sent to the API.
struct ChatRequest: Codable {
    let message: String
    let sessionId: String?
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case message
        case sessionId = "session_id"
        case stream
    }
}

/// Health check response.
struct HealthResponse: Codable {
    let status: String
}

// MARK: - Internal Helpers

/// A streaming SSE event.
struct SSEEvent {
    let id: String?
    let event: String?
    let data: String
}
