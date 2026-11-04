import ApplicationServices
import CoreGraphics
import Darwin
import IOKit.hid
import MalumCore

/// Tells which permissions this process has, through the macOS calls that answer without asking the user.
public struct PermissionProbe: Sendable {
    /// Places only Full Disk Access opens, relative to home. Opening them never makes macOS ask: without
    /// access the open just fails.
    private static let homeProbes = ["Library/Safari"]
    /// Places only Full Disk Access opens, outside home.
    private static let systemProbes = ["/Library/Application Support/com.apple.TCC/TCC.db"]
    /// The option that makes macOS list the app under Accessibility, written out because the
    /// framework's constant isn't safe to read under strict concurrency.
    private static let accessibilityPromptOption = "AXTrustedCheckOptionPrompt"

    /// The user's home folder.
    private let home: String

    /// Creates the probe for the user whose home folder is `home`.
    public init(home: String) {
        self.home = home
    }

    /// Asks macOS to list Malum under `permission` in System Settings, for the permissions an app can ask
    /// for. macOS shows its own prompt only the first time; the user still turns the permission on.
    @MainActor
    public static func request(_ permission: Permission) {
        switch permission {
        case .accessibility:
            _ = AXIsProcessTrustedWithOptions([accessibilityPromptOption: true] as CFDictionary)
        case .inputMonitoring:
            _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        case .screenRecording:
            _ = CGRequestScreenCaptureAccess()
        case .fullDiskAccess, .appManagement, .automation, .localNetwork, .networkVolumes:
            break  // macOS has no way to ask for these; the user adds Malum in System Settings.
        }
    }
}

// MARK: - PermissionCheck

extension PermissionProbe: PermissionCheck {
    /// Whether this process has `permission`. macOS gives no way to tell for App Management,
    /// Automation, Local Network and Network Volumes.
    public func state(of permission: Permission) -> PermissionState {
        switch permission {
        case .accessibility:
            AXIsProcessTrusted() ? .granted : .missing
        case .inputMonitoring:
            IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted ? .granted : .missing
        case .screenRecording:
            CGPreflightScreenCaptureAccess() ? .granted : .missing
        case .fullDiskAccess:
            fullDiskAccess()
        case .appManagement, .automation, .localNetwork, .networkVolumes:
            .unknown
        }
    }

    /// Whether this process has Full Disk Access, found by opening the places only it opens.
    private func fullDiskAccess() -> PermissionState {
        var denied = false
        for path in Self.homeProbes.map({ "\(home)/\($0)" }) + Self.systemProbes {
            let descriptor = open(path, O_RDONLY)
            guard descriptor < 0 else {
                close(descriptor)
                return .granted
            }
            denied = denied || errno == EPERM || errno == EACCES
        }
        return denied ? .missing : .unknown
    }
}
