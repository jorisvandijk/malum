import Synchronization

/// `malum log`: Malum's own entries in the unified log, one short line each, live or for a stretch
/// of time.
public struct LogCommand: Sendable {
    /// The stretch of time the menu's Show log shows.
    public static let lastHour = "1h"

    /// Runs `log`.
    private let runner: any CommandRunner

    /// Creates the command, which runs `log` through `runner`.
    public init(runner: any CommandRunner) {
        self.runner = runner
    }

    /// Writes each entry to `write` as it comes in, or the entries of the `last` stretch of time
    /// when it's set, such as `1h`. Gives whether `log` ran, after reporting why not.
    public func run(
        last: String?, write: @escaping @Sendable (String) -> Void, report: @Sendable (Message) -> Void
    ) async -> Bool {
        let command = last.map(UnifiedLog.show) ?? UnifiedLog.follow()
        let result = await runner.lines(of: command) { line in
            guard let entry = UnifiedLog.entry(line) else { return }
            write(entry.description)
        }
        guard result.succeeded else {
            report(.logUnreadable(reason: result.reason))
            return false
        }
        return true
    }

    /// The entries of the `last` stretch of time, one line each, then why `log` didn't run when
    /// it didn't.
    public func lines(last: String) async -> [String] {
        let lines = Mutex<[String]>([])
        _ = await run(
            last: last, write: { line in lines.withLock { $0.append(line) } },
            report: { message in lines.withLock { $0.append(message.description) } })
        return lines.withLock { $0 }
    }
}
