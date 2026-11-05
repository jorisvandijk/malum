/// Why TOML text couldn't be read.
public enum TOMLReadError: Error, Equatable, Sendable {
    /// The text isn't valid TOML at this line and column.
    case syntax(line: Int, column: Int, reason: String)
    /// The parser failed without saying where.
    case unreadable(reason: String)
}
