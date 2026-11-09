/// How one share fared the last time the Samba module looked.
enum ShareState: Equatable, Sendable {
    /// Mounted at `path`.
    case mounted(path: String)
    /// Unmounted from `path`, because its server stopped answering.
    case unmounted(path: String)
    /// Not mounted, because its server doesn't answer, such as away from home.
    case unreachable
    /// Not mounted, because the login keychain has no password for it.
    case noPassword
    /// Not mounted, because something else is at `path`.
    case taken(path: String)
    /// The password couldn't be read from the keychain.
    case unreadablePassword(TokenStoreError)
    /// macOS didn't mount it.
    case failed(SambaMountError)
    /// Its server stopped answering, and `umount` couldn't take it off `path`.
    case stuck(path: String, reason: String)

    /// Whether it needs the user, which the menu bar shows.
    var isProblem: Bool {
        switch self {
        case .mounted, .unmounted, .unreachable: false
        case .noPassword, .taken, .unreadablePassword, .failed, .stuck: true
        }
    }
}
