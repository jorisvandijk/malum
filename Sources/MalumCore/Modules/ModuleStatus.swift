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

// MARK: - CustomStringConvertible

extension ModuleStatus: CustomStringConvertible {
    /// The status in the words the menu bar uses.
    public var description: String {
        switch self {
        case .off:
            "off"
        case .starting:
            "starting"
        case .running:
            "running"
        case .degraded(let reason):
            "degraded: \(reason)"
        case .failed(let reason):
            "failed: \(reason)"
        case .needsPermission(let missing):
            "needs \(missing.map(\.description).sorted().joined(separator: ", "))"
        }
    }
}
