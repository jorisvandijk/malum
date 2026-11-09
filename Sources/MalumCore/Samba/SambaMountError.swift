/// Why a share didn't mount.
public enum SambaMountError: Error, Equatable, Sendable {
    /// The server refused the user or the password.
    case refused
    /// The server has no share by that name.
    case noShare
    /// The user may not open the share.
    case noAccess
    /// The server stopped answering.
    case noAnswer
    /// Any other error, by its number.
    case other(Int32)

    /// The error macOS's mount `status` stands for, from `errno` and NetFS's own numbers.
    public init(status: Int32) {
        switch status {
        case Self.authFailed, Self.userCancelledAuth: self = .refused
        case Self.noEntry: self = .noShare
        case Self.accessDenied: self = .noAccess
        case Self.timedOut, Self.hostDown, Self.hostUnreachable: self = .noAnswer
        default: self = .other(status)
        }
    }

    /// `EAUTH`.
    private static let authFailed: Int32 = 80
    /// NetFS's `kNetAuthErrorUserCancelled`, which it gives for a refused login without dialogs.
    private static let userCancelledAuth: Int32 = -6_003
    /// `ENOENT`.
    private static let noEntry: Int32 = 2
    /// `EACCES`.
    private static let accessDenied: Int32 = 13
    /// `ETIMEDOUT`.
    private static let timedOut: Int32 = 60
    /// `EHOSTDOWN`.
    private static let hostDown: Int32 = 64
    /// `EHOSTUNREACH`.
    private static let hostUnreachable: Int32 = 65
}
