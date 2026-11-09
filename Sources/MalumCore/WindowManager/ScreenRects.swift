import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// The screen with the menu bar, in AppKit's coordinates (from the bottom left, going up).
public struct ScreenRects: Equatable, Sendable {
    /// The whole screen.
    public let full: CGRect
    /// The part below the menu bar and outside the Dock.
    public let visible: CGRect

    /// Describes a screen.
    public init(full: CGRect, visible: CGRect) {
        self.full = full
        self.visible = visible
    }

    /// The part of the screen that `frame` names, in Accessibility's coordinates.
    func area(_ frame: ScreenFrame) -> CGRect {
        let rect = frame == .full ? full : visible
        return WindowLayout.toAccessibility(rect, mainScreenHeight: full.height)
    }
}
