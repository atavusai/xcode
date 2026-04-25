import Foundation

/// Parses Server-Sent Events (SSE) from a stream of data.
actor SSEParser {
    private var buffer = ""
    private var currentEvent: SSEEvent?

    /// Parses incoming data and returns completed SSE events.
    /// - Parameter data: Raw data from the stream.
    /// - Returns: Array of completed SSE events.
    func parse(_ data: String) -> [SSEEvent] {
        buffer += data
        var events: [SSEEvent] = []
        let lines = buffer.components(separatedBy: "\n")

        // Rebuild buffer from incomplete last line
        if !lines.isEmpty, !buffer.hasSuffix("\n") {
            buffer = lines.last ?? ""
        } else {
            buffer = ""
        }

        for line in lines.dropLast(lines.isEmpty ? 0 : 1) {
            if line.isEmpty {
                // Empty line = event boundary
                if let event = currentEvent {
                    events.append(event)
                    currentEvent = nil
                }
                continue
            }

            if line.hasPrefix("id:") {
                let id = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                if currentEvent != nil {
                    currentEvent = SSEEvent(id: id, event: currentEvent?.event, data: currentEvent?.data ?? "")
                } else {
                    currentEvent = SSEEvent(id: id, event: nil, data: "")
                }
            } else if line.hasPrefix("event:") {
                let event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                if currentEvent != nil {
                    currentEvent = SSEEvent(id: currentEvent?.id, event: event, data: currentEvent?.data ?? "")
                } else {
                    currentEvent = SSEEvent(id: nil, event: event, data: "")
                }
            } else if line.hasPrefix("data:") {
                let data = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if currentEvent != nil {
                    currentEvent = SSEEvent(
                        id: currentEvent?.id,
                        event: currentEvent?.event,
                        data: currentEvent!.data.isEmpty ? data : currentEvent!.data + "\n" + data
                    )
                } else {
                    currentEvent = SSEEvent(id: nil, event: nil, data: data)
                }
            }
            // Ignore comments (lines starting with :) and retry fields
        }

        return events
    }

    /// Resets the parser state.
    func reset() {
        buffer = ""
        currentEvent = nil
    }
}
