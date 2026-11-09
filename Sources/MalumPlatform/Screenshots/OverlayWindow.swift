import AppKit

/// The borderless panel that covers one screen for a screenshot, above everything, menu bar
/// included. It takes keys without making Malum the active app, as the popup does.
@MainActor
final class OverlayWindow: NSPanel {
    /// Covers `frame`, a screen's frame in AppKit's coordinates.
    init(frame: CGRect) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        isMovable = false
        acceptsMouseMovedEvents = true
    }

    /// Not used: the panel is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// Takes the keys, though Malum never becomes the active app.
    override var canBecomeKey: Bool { true }

    /// Never the main window.
    override var canBecomeMain: Bool { false }
}
