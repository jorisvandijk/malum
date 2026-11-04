/// One tagged line for the user, such as `[error] unknown command: foo`.
public struct Message: Equatable, Sendable {
    /// How serious it is.
    public let level: Level
    /// What happened.
    public let text: MessageText

    /// Creates a message with its level and text.
    public init(_ level: Level, _ text: MessageText) {
        self.level = level
        self.text = text
    }
}

// MARK: - CustomStringConvertible

extension Message: CustomStringConvertible {
    /// The message with its tag in front.
    public var description: String { "[\(level.rawValue)] \(text)" }
}
