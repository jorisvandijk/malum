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
