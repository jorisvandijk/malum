/// Why talking to GitHub failed.
public enum GitHubError: Error, Equatable, Sendable {
    /// GitHub couldn't be reached.
    case unreachable(reason: String)
    /// GitHub answered with an HTTP status other than the one expected.
    case refused(status: Int)
    /// GitHub's answer couldn't be read.
    case unreadable
    /// The download couldn't be saved at the path.
    case unsaved(path: String, reason: String)
}

// MARK: - ReportableError

extension GitHubError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unreachable(let reason):
            "couldn't reach GitHub: \(reason)"
        case .refused(let status):
            "GitHub answered with HTTP \(status)"
        case .unreadable:
            "GitHub sent an answer Malum can't read"
        case .unsaved(let path, let reason):
            "couldn't save \(private: path): \(reason)"
        }
    }
}
