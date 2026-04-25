import SwiftUI

/// A theme configuration for the Atavus AI chat UI components.
public struct AtavusChatTheme {
    public var primaryColor: Color
    public var secondaryColor: Color
    public var bubbleBackgroundColor: Color
    public var bubbleTextColor: Color
    public var userBubbleColor: Color
    public var userTextColor: Color
    public var backgroundColor: Color
    public var inputBackgroundColor: Color
    public var textColor: Color
    public var font: Font

    public static let `default` = AtavusChatTheme(
        primaryColor: Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255), // purple-500
        secondaryColor: Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255), // amber-500
        bubbleBackgroundColor: Color.white.opacity(0.1),
        bubbleTextColor: Color.white,
        userBubbleColor: Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255),
        userTextColor: Color.white,
        backgroundColor: Color.black.opacity(0.95),
        inputBackgroundColor: Color.white.opacity(0.08),
        textColor: Color.white,
        font: .body
    )

    public init(
        primaryColor: Color = .default.primaryColor,
        secondaryColor: Color = .default.secondaryColor,
        bubbleBackgroundColor: Color = .default.bubbleBackgroundColor,
        bubbleTextColor: Color = .default.bubbleTextColor,
        userBubbleColor: Color = .default.userBubbleColor,
        userTextColor: Color = .default.userTextColor,
        backgroundColor: Color = .default.backgroundColor,
        inputBackgroundColor: Color = .default.inputBackgroundColor,
        textColor: Color = .default.textColor,
        font: Font = .default.font
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.bubbleBackgroundColor = bubbleBackgroundColor
        self.bubbleTextColor = bubbleTextColor
        self.userBubbleColor = userBubbleColor
        self.userTextColor = userTextColor
        self.backgroundColor = backgroundColor
        self.inputBackgroundColor = inputBackgroundColor
        self.textColor = textColor
        self.font = font
    }
}

/// A chat message bubble view.
struct ChatBubble: View {
    let text: String
    let isUser: Bool
    let theme: AtavusChatTheme

    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(text)
                .font(theme.font)
                .foregroundColor(isUser ? theme.userTextColor : theme.bubbleTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? theme.userBubbleColor : theme.bubbleBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            if !isUser { Spacer() }
        }
    }
}

/// A loading indicator for when the AI is thinking.
struct ThinkingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear { animate = true }
    }
}
