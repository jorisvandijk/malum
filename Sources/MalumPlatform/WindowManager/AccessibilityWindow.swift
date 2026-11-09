import ApplicationServices
import CoreGraphics
import MalumCore

/// One app window, reached through Accessibility.
@MainActor
final class AccessibilityWindow {
    /// Accessibility's names for what a window holds, written out because the framework's
    /// constants aren't safe to read under strict concurrency.
    private enum Attribute {
        static let role = "AXRole"
        static let subrole = "AXSubrole"
        static let title = "AXTitle"
        static let modal = "AXModal"
        static let position = "AXPosition"
        static let size = "AXSize"
        static let minimized = "AXMinimized"
        static let fullScreen = "AXFullScreen"
        /// Set on an app by assistive tools; while it's on, the app animates every resize.
        static let enhancedUserInterface = "AXEnhancedUserInterface"
    }

    /// The window.
    let window: AccessibilityElement
    /// Its app, whose enhanced user interface is switched off around each change.
    private let app: AccessibilityElement

    /// Wraps `window`, a window of `app`.
    init(_ window: AXUIElement, of app: AXUIElement) {
        self.window = AccessibilityElement(element: window)
        self.app = AccessibilityElement(element: app)
    }

    /// Runs `change` with the app's enhanced user interface off, and puts it back after, as
    /// Rectangle and yabai do, so the change isn't animated.
    private func withoutAnimation(_ change: () -> Void) {
        let enhanced = app.bool(Attribute.enhancedUserInterface) ?? false
        if enhanced {
            app.set(Attribute.enhancedUserInterface, false)
        }
        change()
        if enhanced {
            app.set(Attribute.enhancedUserInterface, true)
        }
    }
}

// MARK: - AppWindow

extension AccessibilityWindow: AppWindow {
    /// What the window says about itself.
    var facts: WindowFacts {
        WindowFacts(
            role: window.string(Attribute.role), subrole: window.string(Attribute.subrole),
            title: window.string(Attribute.title), isModal: window.bool(Attribute.modal) ?? false,
            isResizable: window.isSettable(Attribute.size), isFullScreen: window.bool(Attribute.fullScreen) ?? false)
    }

    /// Where the window is, from the top left of the main screen.
    var frame: CGRect? {
        guard let origin = window.point(Attribute.position), let size = window.size(Attribute.size) else { return nil }
        return CGRect(origin: origin, size: size)
    }

    /// Whether the window is in the Dock.
    var isMinimized: Bool {
        window.bool(Attribute.minimized) ?? false
    }

    /// Size, position, then size again, without animation.
    func setFrame(_ frame: CGRect) {
        withoutAnimation {
            window.set(Attribute.size, size: frame.size)
            window.set(Attribute.position, point: frame.origin)
            window.set(Attribute.size, size: frame.size)
        }
    }

    /// Moves the window without animation.
    func setOrigin(_ origin: CGPoint) {
        withoutAnimation {
            window.set(Attribute.position, point: origin)
        }
    }

    /// Whether `other` wraps the same window.
    func isSame(as other: any AppWindow) -> Bool {
        guard let other = other as? AccessibilityWindow else { return false }
        return CFEqual(window.element, other.window.element)
    }
}
