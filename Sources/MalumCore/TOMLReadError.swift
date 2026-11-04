/// Why TOML text couldn't be read.
public enum TOMLReadError: Error, Equatable, Sendable {
    /// The text isn't valid TOML at this line and column.
    case syntax(line: Int, column: Int, reason: String)
    /// The parser failed without saying where.
    case unreadable(reason: String)
}

// MARK: - ReportableError

extension TOMLReadError: ReportableError {
    /// The problem as the user sees it, starting with where it is when that's known.
    public var text: MessageText {
        switch self {
        case .syntax(let line, let column, let reason):
            "line \(line), column \(column): \(reason)"
        case .unreadable(let reason):
            MessageText(reason)
        }
    }
}
