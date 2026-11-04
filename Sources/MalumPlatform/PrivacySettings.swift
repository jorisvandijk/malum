import AppKit
import MalumCore

/// Where System Settings grants each permission.
public enum PrivacySettings {
    /// The start of every Privacy & Security page's address.
    private static let base = "x-apple.systempreferences:com.apple.preference.security?"

    /// Opens the page in System Settings where `permission` is granted, and says whether it opened.
    @MainActor
    @discardableResult
    public static func open(_ permission: Permission) -> Bool {
        guard let url = URL(string: base + page(for: permission)) else { return false }
        return NSWorkspace.shared.open(url)
    }

    /// The name System Settings gives the page for `permission`.
    private static func page(for permission: Permission) -> String {
        switch permission {
        case .accessibility:
            "Privacy_Accessibility"
        case .inputMonitoring:
            "Privacy_ListenEvent"
        case .screenRecording:
            "Privacy_ScreenCapture"
        case .fullDiskAccess:
            "Privacy_AllFiles"
        case .appManagement:
            "Privacy_AppBundles"
        case .automation:
            "Privacy_Automation"
        case .localNetwork:
            "Privacy_LocalNetwork"
        case .networkVolumes:
            "Privacy_FilesAndFolders"
        }
    }
}
