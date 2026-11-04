/// How serious a log entry is, shown as its tag.
public enum LogLevel: String, Sendable {
    /// Detail for tracking down a problem. The system log only keeps it while someone is watching.
    case debug
    /// A state change, such as a module starting.
    case info
    /// Something the menu bar shows as needing attention.
    case warn
    /// Something the menu bar shows as failed.
    case error

    /// The log level of a message for the user.
    public init(_ level: Level) {
        switch level {
        case .info:
            self = .info
        case .warn:
            self = .warn
        case .error:
            self = .error
        }
    }
}
