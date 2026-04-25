import Foundation

/// Configuration for the Atavus AI SDK client.
public struct AtavusConfig {
    /// Base URL for the Atavus API.
    public var baseURL: String
    /// Request timeout in seconds.
    public var timeout: TimeInterval
    /// Logging level.
    public var logLevel: LogLevel

    public enum LogLevel: Int, Comparable {
        case none = 0
        case error = 1
        case info = 2
        case debug = 3

        public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Default configuration for the Atavus AI SDK.
    public static let `default` = AtavusConfig(
        baseURL: "https://atavus.ai/api/v1",
        timeout: 30.0,
        logLevel: .error
    )

    public init(
        baseURL: String = "https://atavus.ai/api/v1",
        timeout: TimeInterval = 30.0,
        logLevel: LogLevel = .error
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.logLevel = logLevel
    }
}
