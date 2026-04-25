import Foundation

/// Errors that can occur when using the Atavus AI SDK.
public enum AtavusError: LocalizedError {
    /// Invalid API key or authentication failure.
    case authentication(String)
    /// Network connectivity issue.
    case network(Error)
    /// Server returned an error.
    case server(statusCode: Int, message: String)
    /// Failed to decode the response.
    case decoding(Error)
    /// Rate limit exceeded.
    case rateLimit(retryAfter: TimeInterval)
    /// Invalid request parameters.
    case invalidRequest(String)
    /// SDK not initialized.
    case notInitialized
    /// Session error.
    case session(String)
    /// Streaming error.
    case stream(String)
    /// Unknown error.
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .authentication(let msg): return "Authentication failed: \(msg)"
        case .network(let err): return "Network error: \(err.localizedDescription)"
        case .server(let code, let msg): return "Server error (\(code)): \(msg)"
        case .decoding(let err): return "Decoding error: \(err.localizedDescription)"
        case .rateLimit(let retry): return "Rate limited. Retry after \(retry)s"
        case .invalidRequest(let msg): return "Invalid request: \(msg)"
        case .notInitialized: return "AtavusClient not initialized"
        case .session(let msg): return "Session error: \(msg)"
        case .stream(let msg): return "Stream error: \(msg)"
        case .unknown(let msg): return "Unknown error: \(msg)"
        }
    }
}
