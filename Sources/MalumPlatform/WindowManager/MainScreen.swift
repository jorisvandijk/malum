import AppKit
import MalumCore

/// The screen with the menu bar, through `NSScreen`.
@MainActor
public final class MainScreen {
    /// Creates the reader.
    public init() {}
}

// MARK: - Screens

extension MainScreen: Screens {
    /// The first screen, which is the one with the menu bar, or nil when there's none.
    public func main() -> ScreenRects? {
        NSScreen.screens.first.map { ScreenRects(full: $0.frame, visible: $0.visibleFrame) }
    }
}
