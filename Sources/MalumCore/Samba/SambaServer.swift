/// One Samba server in `samba.toml`, with the shares to mount from it.
public struct SambaServer: Equatable, Sendable {
    /// The name `malum samba password` takes, such as `nas`.
    public let name: String
    /// The server's host name or address.
    public let host: String
    /// The user to log in as.
    public let user: String
    /// The shares to mount under `/Volumes`.
    public let shares: [String]

    /// Who logs in where, as the keychain item's account: `user@host`.
    public var account: String { "\(user)@\(host)" }
}
