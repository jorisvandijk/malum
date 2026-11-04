/// One line of the log.
public struct LogEntry: Equatable, Sendable {
    /// The part of Malum it's about: the app, or a module's id.
    public let category: String
    /// How serious it is.
    public let level: LogLevel
    /// What happened, with private parts marked.
    public let text: MessageText

    /// Creates an entry.
    public init(category: String, level: LogLevel, text: MessageText) {
        self.category = category
        self.level = level
        self.text = text
    }

    /// The entry as the log shows it, with private parts hidden.
    public var redacted: String { "[\(level.rawValue)] \(text.redacted)" }
}

// MARK: - CustomStringConvertible

extension LogEntry: CustomStringConvertible {
    /// The entry with its tag in front, private parts included.
    public var description: String { "[\(level.rawValue)] \(text)" }
}
