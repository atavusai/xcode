# Atavus AI — iOS SDK

Integrate Atavus AI assistants into your iOS app with native Swift.

## Requirements

- iOS 16.0+ / macOS 13.0+ / watchOS 9.0+ / tvOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add the package in Xcode:
1. **File → Add Package Dependencies...**
2. Paste: `https://github.com/atavusai/xcode.git`
3. Select version: **1.0.0**
4. Add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/atavusai/xcode.git", from: "1.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["AtavusAI"])
]
```

## Quick Start

```swift
import AtavusAI

// Initialize the client
let client = AtavusClient(
    apiKey: "atavus_sk_your_key_here",
    assistantId: "ast_your_assistant_id"
)

// Send a message
Task {
    let response = try await client.sendMessage("What's the weather?")
    print(response.text)
}

// Stream response
let stream = try await client.streamMessage("Write a poem")
for try await chunk in stream {
    print(chunk.text, terminator: "")
}
```

## Sessions (Conversation Context)

```swift
let session = try await client.createSession()

try await session.send("My name is Alice")
let reply = try await session.send("What's my name?")
// reply.text == "Your name is Alice!"
```

## Chat Widget (SwiftUI)

```swift
import SwiftUI
import AtavusAI

struct ContentView: View {
    let client = AtavusClient(apiKey: "...", assistantId: "...")
    
    var body: some View {
        ZStack {
            // Your app content
        }
        .overlay(alignment: .bottomTrailing) {
            AtavusChatButton(client: client)
                .padding()
        }
    }
}
```

## Configuration

```swift
let config = AtavusConfig(
    baseURL: "https://atavus.ai/api/v1",
    timeout: 60,
    logLevel: .debug
)
let client = AtavusClient(apiKey: "...", assistantId: "...", config: config)
```

## Error Handling

```swift
do {
    let response = try await client.sendMessage("Hello")
} catch AtavusError.authentication(let msg) {
    // Invalid API key
} catch AtavusError.rateLimit(let retryAfter) {
    // Too many requests — wait retryAfter seconds
} catch AtavusError.network(let error) {
    // No internet connection
} catch {
    // Other errors
}
```
