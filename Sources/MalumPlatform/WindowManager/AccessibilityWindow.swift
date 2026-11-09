import ApplicationServices
import CoreGraphics
import MalumCore

/// One app window, reached through Accessibility.
@MainActor
final class AccessibilityWindow {
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
        let enhanced = app.bool(AccessibilityName.enhancedUserInterface) ?? false
        if enhanced {
            app.set(AccessibilityName.enhancedUserInterface, false)
        }
        change()
        if enhanced {
            app.set(AccessibilityName.enhancedUserInterface, true)
        }
    }
}

// MARK: - AppWindow

extension AccessibilityWindow: AppWindow {
    /// What the window says about itself.
    var facts: WindowFacts {
        WindowFacts(
            role: window.string(AccessibilityName.role), subrole: window.string(AccessibilityName.subrole),
            title: window.string(AccessibilityName.title), isModal: window.bool(AccessibilityName.modal) ?? false,
            isResizable: window.isSettable(AccessibilityName.size),
            isFullScreen: window.bool(AccessibilityName.fullScreen) ?? false)
    }

    /// Where the window is, from the top left of the main screen.
    var frame: CGRect? {
        guard let origin = window.point(AccessibilityName.position), let size = window.size(AccessibilityName.size)
        else { return nil }
        return CGRect(origin: origin, size: size)
    }

    /// Whether the window is in the Dock.
    var isMinimized: Bool {
        window.bool(AccessibilityName.minimized) ?? false
    }

    /// Size, position, then size again, without animation.
    func setFrame(_ frame: CGRect) {
        withoutAnimation {
            window.set(AccessibilityName.size, size: frame.size)
            window.set(AccessibilityName.position, point: frame.origin)
            window.set(AccessibilityName.size, size: frame.size)
        }
    }

    /// Moves the window without animation.
    func setOrigin(_ origin: CGPoint) {
        withoutAnimation {
            window.set(AccessibilityName.position, point: origin)
        }
    }

    /// Whether `other` wraps the same window.
    func isSame(as other: any AppWindow) -> Bool {
        guard let other = other as? AccessibilityWindow else { return false }
        return CFEqual(window.element, other.window.element)
    }
}
