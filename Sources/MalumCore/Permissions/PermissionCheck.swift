/// Tells which permissions the running process has.
///
/// A command run in a terminal gets the terminal's permissions, so there it tells what the terminal has.
public protocol PermissionCheck: Sendable {
    /// Whether the process has `permission`.
    func state(of permission: Permission) -> PermissionState
}

extension PermissionCheck {
    /// The permissions in `needed` that are known to be missing. One macOS can't tell about isn't
    /// counted, so it never keeps a module off.
    public func missing(from needed: Set<Permission>) -> Set<Permission> {
        needed.filter { state(of: $0) == .missing }
    }
}
