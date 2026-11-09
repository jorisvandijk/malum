import AppKit
import ApplicationServices
import MalumCore

/// Reaches running apps' windows through Accessibility.
@MainActor
public final class AccessibilityWindows {
    /// How long, in seconds, an Accessibility call waits for an app before it gives up. macOS waits
    /// six, which lets one hung app stall the window manager.
    private static let messagingTimeout: Float = 1
    /// The pointer's main button in `NSEvent.pressedMouseButtons`.
    private static let mainButton = 1

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

    /// Whether the pointer's main button is held now.
    public var isPointerDown: Bool {
        NSEvent.pressedMouseButtons & Self.mainButton != 0
    }

    /// Where the pointer is, flipped from AppKit's coordinates by the height of the screen with the
    /// menu bar, where both start.
    public var pointerLocation: CGPoint {
        let location = NSEvent.mouseLocation
        let height = NSScreen.screens.first?.frame.height ?? location.y
        return CGPoint(x: location.x, y: height - location.y)
    }
}
