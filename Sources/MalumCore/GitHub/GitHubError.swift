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
