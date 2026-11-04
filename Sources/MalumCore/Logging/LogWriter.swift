/// Where log entries end up: the system log in the app, a recording in tests.
public protocol LogWriter: Sendable {
    /// Writes one entry.
    func write(_ entry: LogEntry)
}
