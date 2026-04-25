import Foundation

/// The main client for interacting with the Atavus AI API.
///
/// ```swift
/// let client = AtavusClient(apiKey: "atavus_sk_...", assistantId: "ast_...")
/// let response = try await client.sendMessage("Hello!")
/// print(response.text)
/// ```
public final class AtavusClient: @unchecked Sendable {
    private let apiKey: String
    private let assistantId: String
    private let config: AtavusConfig
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Creates a new Atavus AI client.
    /// - Parameters:
    ///   - apiKey: Your Atavus API key.
    ///   - assistantId: The ID of the assistant to chat with.
    ///   - config: Optional configuration. Defaults to ``AtavusConfig/default``.
    public init(apiKey: String, assistantId: String, config: AtavusConfig = .default) {
        self.apiKey = apiKey
        self.assistantId = assistantId
        self.config = config

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = config.timeout
        cfg.timeoutIntervalForResource = config.timeout * 2
        cfg.waitsForConnectivity = true
        self.session = URLSession(configuration: cfg)

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Public API

    /// Checks connectivity to the Atavus API.
    /// - Returns: `true` if the API is reachable.
    public func healthCheck() async throws -> Bool {
        let request = try buildRequest(
            path: "/health",
            method: "GET"
        )
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AtavusError.network(URLError(.badServerResponse))
        }
        return httpResponse.statusCode == 200
    }

    /// Sends a message and returns the full response.
    /// - Parameters:
    ///   - text: The message text.
    ///   - sessionId: Optional session ID for continuing a conversation.
    /// - Returns: The assistant's response.
    public func sendMessage(_ text: String, sessionId: String? = nil) async throws -> AssistantResponse {
        log(.info, "sendMessage: \(text.prefix(80))...")

        let body = ChatRequest(message: text, sessionId: sessionId, stream: false)
        let request = try buildRequest(
            path: "/chat/\(assistantId)",
            method: "POST",
            body: body
        )

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(AssistantResponse.self, from: data)
        } catch {
            throw AtavusError.decoding(error)
        }
    }

    /// Sends a message and streams the response in chunks.
    /// - Parameters:
    ///   - text: The message text.
    ///   - sessionId: Optional session ID for continuing a conversation.
    /// - Returns: An async throwing stream of text chunks.
    public func streamMessage(
        _ text: String,
        sessionId: String? = nil
    ) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        log(.info, "streamMessage: \(text.prefix(80))...")

        let body = ChatRequest(message: text, sessionId: sessionId, stream: true)
        let request = try buildRequest(
            path: "/chat/\(assistantId)/stream",
            method: "POST",
            body: body
        )

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    try validateResponse(response)

                    let parser = SSEParser()
                    for try await line in bytes.lines {
                        let events = await parser.parse(line + "\n")
                        for event in events {
                            if let data = event.data.data(using: .utf8) {
                                if let streamEnd = try? decoder.decode([String: String].self, from: data),
                                   streamEnd["finish_reason"] != nil {
                                    let chunk = StreamChunk(
                                        text: "",
                                        sessionId: streamEnd["session_id"],
                                        finishReason: streamEnd["finish_reason"],
                                        error: nil
                                    )
                                    continuation.yield(chunk)
                                    continuation.finish()
                                    return
                                }

                                if let chunk = try? decoder.decode(StreamChunk.self, from: data) {
                                    continuation.yield(chunk)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    if let atavusError = error as? AtavusError {
                        continuation.finish(throwing: atavusError)
                    } else {
                        continuation.finish(throwing: AtavusError.stream(error.localizedDescription))
                    }
                }
            }
        }
    }

    /// Creates a new conversation session for maintaining context.
    /// - Returns: A ``Session`` object that preserves message history.
    public func createSession() async throws -> Session {
        log(.info, "createSession")

        let request = try buildRequest(
            path: "/chat/\(assistantId)/session",
            method: "POST"
        )
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        let sessionData = try decoder.decode(ChatSessionData.self, from: data)
        return Session(
            client: self,
            sessionId: sessionData.id,
            assistantId: assistantId
        )
    }

    // MARK: - Internal

    private func buildRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: config.baseURL + path) else {
            throw AtavusError.invalidRequest("Invalid URL: \(config.baseURL)\(path)")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("AtavusAI-SDK/iOS", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = config.timeout
        return req
    }

    private func buildRequest<T: Encodable>(path: String, method: String, body: T) throws -> URLRequest {
        var req = try buildRequest(path: path, method: method)
        req.httpBody = try encoder.encode(body)
        return req
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AtavusError.network(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw AtavusError.authentication("Invalid or expired API key")
        case 403:
            throw AtavusError.authentication("Access forbidden")
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) } ?? 60
            throw AtavusError.rateLimit(retryAfter: retryAfter)
        case 400...499:
            let message = data.flatMap { try? decoder.decode([String: String].self, from: $0) }?["detail"]
                ?? "Client error"
            throw AtavusError.server(statusCode: httpResponse.statusCode, message: message)
        default:
            let message = data.flatMap { try? decoder.decode([String: String].self, from: $0) }?["detail"]
                ?? "Server error"
            throw AtavusError.server(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func log(_ level: AtavusConfig.LogLevel, _ message: String) {
        guard level <= config.logLevel else { return }
        let prefix: String
        switch level {
        case .error: prefix = "❌"
        case .info: prefix = "ℹ️"
        case .debug: prefix = "🔍"
        case .none: return
        }
        print("[AtavusAI] \(prefix) \(message)")
    }
}
