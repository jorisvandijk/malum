import Foundation

/// The command line's output: plain text to standard output, messages to standard error.
///
/// This is the only place that writes to the terminal.
public struct Terminal: Sendable {
    /// Creates the terminal output.
    public init() {}

    /// Writes a line of plain output, such as the version.
    public func write(_ line: String) {
        print(line)
    }

    /// Writes a tagged message.
    public func report(_ message: Message) {
        FileHandle.standardError.write(Data((message.description + "\n").utf8))
    }
}
