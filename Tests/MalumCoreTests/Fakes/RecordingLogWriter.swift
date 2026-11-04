import Synchronization

@testable import MalumCore

/// Keeps every entry it's given instead of writing it anywhere.
final class RecordingLogWriter: LogWriter {
    /// Every entry, in order.
    private let written = Mutex<[LogEntry]>([])

    var entries: [LogEntry] { written.withLock { $0 } }

    func write(_ entry: LogEntry) {
        written.withLock { $0.append(entry) }
    }
}
