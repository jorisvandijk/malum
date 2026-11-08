/// Why talking to GitHub failed.
public enum GitHubError: Error, Equatable, Sendable {
    /// GitHub couldn't be reached.
    case unreachable(reason: String)
    /// The address isn't a link.
    case notALink(address: String)
    /// GitHub answered with an HTTP status other than the one expected.
    case refused(status: Int)
    /// GitHub's answer couldn't be read.
    case unreadable
    /// The download couldn't be saved at the path.
    case unsaved(path: String, reason: String)
    /// GitHub refused the token: it's wrong, revoked or expired.
    case tokenRefused
    /// The token works, but can't read the repository.
    case tokenCantRead(repo: String)
    /// Malum's own repository can't be seen without a token, since it's private.
    case needsToken(repo: String)
}
