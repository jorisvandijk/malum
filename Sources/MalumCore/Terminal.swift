import Foundation

/// The command line's output: plain text to standard output, messages to standard error.
///
/// This is the only place that writes to the terminal. When standard error is a terminal and
/// `NO_COLOR` isn't set, the word in each message's tag is coloured; the log never is.
public struct Terminal: Sendable {
    /// The escape that starts a colour.
    private static let escape = "\u{1B}["
    /// The escape that ends a colour.
    private static let reset = "\u{1B}[0m"

    /// Whether tags are coloured.
    private let colorsTags: Bool

    /// Creates the terminal output, colouring tags when standard error is a terminal and
    /// `NO_COLOR` isn't set.
    public init() {
        colorsTags = Self.wantsColor(
            isTerminal: isatty(STDERR_FILENO) == 1, environment: ProcessInfo.processInfo.environment)
    }

    /// Writes a line of plain output, such as the version.
    public func write(_ line: String) {
        print(line)
    }

    /// Writes a tagged message.
    public func report(_ message: Message) {
        FileHandle.standardError.write(Data((Self.format(message, color: colorsTags) + "\n").utf8))
    }

    /// The message as the terminal shows it: with `color`, the tag's word is green for info,
    /// yellow for warn and red for error, and the brackets and text stay plain.
    public static func format(_ message: Message, color: Bool) -> String {
        guard color else { return message.description }
        let code = colorCode(message.level)
        return "[\(escape)\(code)m\(message.level.rawValue)\(reset)] \(message.text)"
    }

    /// Whether to colour tags: only on a terminal, and never when `NO_COLOR` is set to anything
    /// but an empty value, as https://no-color.org asks.
    public static func wantsColor(isTerminal: Bool, environment: [String: String]) -> Bool {
        guard isTerminal else { return false }
        return environment["NO_COLOR", default: ""].isEmpty
    }

    /// The terminal's colour code for a level.
    private static func colorCode(_ level: Level) -> String {
        switch level {
        case .info:
            "32"
        case .warn:
            "33"
        case .error:
            "31"
        }
    }
}
