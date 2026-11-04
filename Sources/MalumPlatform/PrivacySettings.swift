import Foundation
import MalumCore

/// Where System Settings grants each permission.
enum PrivacySettings {
    /// The start of every Privacy & Security page's address.
    private static let base = "x-apple.systempreferences:com.apple.preference.security?"

    /// The page in System Settings where `permission` is granted.
    static func url(for permission: Permission) -> URL? {
        URL(string: base + page(for: permission))
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
