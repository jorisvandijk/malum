/// The words for loading `malum.toml` and reading TOML from dots.
extension Message {
    /// `path` was loaded.
    static func loaded(_ path: String) -> Message {
        Message(.info, "loaded \(private: path)")
    }

    /// `module`'s table has a problem, so it keeps the settings it had.
    static func keepsLastGoodSettings(_ module: String) -> Message {
        Message(.warn, "\(module) keeps its last good settings")
    }
}

extension ConfigProblem {
    /// The problem as the user sees it, starting with where it is.
    public var message: Message {
        guard let line else { return Message(level, text) }
        guard let column else { return Message(level, "\(file) line \(line): \(text)") }
        return Message(level, "\(file) line \(line), column \(column): \(text)")
    }
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
