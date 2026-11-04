import MalumCore
import os

/// Writes Malum's log to the macOS system log, with the bundle ID as subsystem.
///
/// The public text is logged as public. Private parts show as `<private>` in it, and their values
/// follow at the end of the line as one private value, which the system log hides too.
public struct SystemLog: LogWriter {
    /// Creates the writer.
    public init() {}

    /// Writes one entry under its category.
    public func write(_ entry: LogEntry) {
        let logger = Logger(subsystem: Project.bundleID, category: entry.category)
        let shown = entry.redacted
        let type = Self.type(of: entry.level)
        let hidden = entry.text.hidden
        guard !hidden.isEmpty else {
            logger.log(level: type, "\(shown, privacy: .public)")
            return
        }
        let values = hidden.joined(separator: ", ")
        logger.log(level: type, "\(shown, privacy: .public) \(values, privacy: .private)")
    }

    /// The system log's type for a level. Warnings and errors both show in the menu bar, so both
    /// are errors to the system log; the tag tells them apart.
    private static func type(of level: LogLevel) -> OSLogType {
        switch level {
        case .debug:
            .debug
        case .info:
            .info
        case .warn, .error:
            .error
        }
    }
}
