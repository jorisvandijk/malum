import Foundation

/// Every way Malum runs macOS's `log`, which reads the unified log, and what it makes of its lines.
public enum UnifiedLog {
    /// Where macOS keeps `log`.
    public static let path = "/usr/bin/log"
    /// Seconds a live view runs before it's stopped: a day, so it runs until the user stops it.
    private static let followSeconds = 86_400
    /// Seconds reading a stretch of the log may take: a long stretch takes a while.
    private static let showSeconds = 300
    /// Where the time of day starts and ends in an entry's timestamp, `2026-11-15 00:12:01.234+0100`.
    private static let timeOfDay = (start: 11, length: 8)
    /// What the log shows for the private values at the end of an entry.
    private static let privateTail = " <private>"

    /// Malum's own entries, as `log` filters them.
    private static let predicate = "subsystem == \"\(Project.bundleID)\""

    /// Shows Malum's entries as they come in, one JSON object per line.
    public static func follow() -> Command {
        Command(
            path, ["stream", "--style", "ndjson", "--level", "info", "--predicate", predicate],
            timeoutSeconds: followSeconds)
    }

    /// Shows Malum's entries of the `last` stretch of time, such as `1h`, one JSON object per line.
    public static func show(last: String) -> Command {
        Command(
            path, ["show", "--style", "ndjson", "--info", "--last", last, "--predicate", predicate],
            timeoutSeconds: showSeconds)
    }

    /// Whether `text` is a stretch of time `show` takes: a whole number and `s`, `m`, `h` or `d`.
    public static func isStretch(_ text: String) -> Bool {
        guard let unit = text.last, "smhd".contains(unit) else { return false }
        let number = text.dropLast()
        return !number.isEmpty && number.allSatisfy(\.isASCII) && number.allSatisfy(\.isNumber)
    }

    /// The entry in `line`, one line of `follow` or `show`, or nil for the lines around the entries.
    public static func entry(_ line: String) -> LogLine? {
        struct Fields: Decodable {
            let timestamp: String
            let category: String
            let eventMessage: String
        }
        guard line.hasPrefix("{") else { return nil }
        let decoder = JSONDecoder()
        guard let fields = try? decoder.decode(Fields.self, from: Data(line.utf8)) else { return nil }  // Not an entry.
        let time = fields.timestamp.dropFirst(timeOfDay.start).prefix(timeOfDay.length)
        var text = fields.eventMessage
        if text.hasSuffix(privateTail) { text.removeLast(privateTail.count) }
        return LogLine(time: String(time), category: fields.category, text: text)
    }
}
