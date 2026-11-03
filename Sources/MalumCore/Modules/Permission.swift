/// A macOS privacy permission a module can need, as listed in System Settings.
public enum Permission: String, CaseIterable, Sendable {
    /// Control other apps and their windows.
    case accessibility
    /// Watch the keyboard.
    case inputMonitoring
    /// Capture the screen.
    case screenRecording
    /// Read and write files other apps protect.
    case fullDiskAccess
    /// Update and delete other apps.
    case appManagement
    /// Control other apps through Apple events.
    case automation
    /// Find and reach devices on the local network.
    case localNetwork
    /// Use network volumes.
    case networkVolumes
}

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
