// MARK: - CustomStringConvertible

extension Permission: CustomStringConvertible {
    /// The permission's name as System Settings shows it.
    public var description: String {
        switch self {
        case .accessibility:
            "Accessibility"
        case .inputMonitoring:
            "Input Monitoring"
        case .screenRecording:
            "Screen Recording"
        case .fullDiskAccess:
            "Full Disk Access"
        case .appManagement:
            "App Management"
        case .automation:
            "Automation"
        case .localNetwork:
            "Local Network"
        case .networkVolumes:
            "Network Volumes"
        }
    }
}
