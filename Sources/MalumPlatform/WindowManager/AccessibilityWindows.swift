import ApplicationServices
import MalumCore

/// Reaches running apps' windows through Accessibility.
@MainActor
public final class AccessibilityWindows {
    /// How long, in seconds, an Accessibility call waits for an app before it gives up. macOS waits
    /// six, which lets one hung app stall the window manager.
    private static let messagingTimeout: Float = 1

    /// Sets the short wait for every Accessibility call Malum makes.
    public init() {
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), Self.messagingTimeout)
    }
}

// MARK: - WindowAccess

extension AccessibilityWindows: WindowAccess {
    /// Watches the app with process ID `pid`, or gives nil when it doesn't answer yet.
    public func watch(_ pid: Int32, onChange: @escaping @MainActor (WindowEvent) -> Void) -> (any WatchedApp)? {
        AccessibilityApp(pid: pid, onChange: onChange)
    }
}
