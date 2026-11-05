/// Where a module is, as the menu bar shows it.
public enum ModuleStatus: Equatable, Sendable {
    /// Switched off in `malum.toml`, or not started yet.
    case off
    /// Starting up.
    case starting
    /// Working as it should.
    case running
    /// Running, but something is wrong, such as a config table it couldn't use.
    case degraded(reason: String)
    /// Stopped by an error.
    case failed(reason: String)
    /// Waiting for permissions the user hasn't granted yet.
    case needsPermission(Set<Permission>)

    /// Whether the module is doing its work, even if not everything is right.
    public var isActive: Bool {
        switch self {
        case .running, .degraded:
            true
        case .off, .starting, .failed, .needsPermission:
            false
        }
    }
}
