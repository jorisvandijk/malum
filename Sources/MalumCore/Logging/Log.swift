/// Writes to the log under one category. The app logs under `app`, and each module under its id.
public struct Log: Sendable {
    /// The category of everything that isn't a module.
    public static let appCategory = "app"

    /// The category entries go under.
    public let category: String
    /// Where entries end up.
    private let writer: any LogWriter

    /// Creates a log that writes to `writer` under `category`.
    public init(category: String = appCategory, writer: any LogWriter) {
        self.category = category
        self.writer = writer
    }

    /// The same log, under the module's own category.
    public func module(_ id: String) -> Log {
        Log(category: id, writer: writer)
    }

    /// Logs detail for tracking down a problem.
    public func debug(_ text: MessageText) {
        write(.debug, text)
    }

    /// Logs a state change.
    public func info(_ text: MessageText) {
        write(.info, text)
    }

    /// Logs something that needs attention.
    public func warn(_ text: MessageText) {
        write(.warn, text)
    }

    /// Logs a failure.
    public func error(_ text: MessageText) {
        write(.error, text)
    }

    /// Logs a message the user is shown, at its own level.
    public func report(_ message: Message) {
        write(LogLevel(message.level), message.text)
    }

    /// Hands one entry to the writer.
    private func write(_ level: LogLevel, _ text: MessageText) {
        writer.write(LogEntry(category: category, level: level, text: text))
    }
}
