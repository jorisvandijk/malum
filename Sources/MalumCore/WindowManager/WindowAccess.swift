import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// Reaches running apps' windows through Accessibility, for the window manager. Creating the real
/// one, `AccessibilityWindows` in MalumPlatform, also keeps a hung app from stalling Malum: every
/// Accessibility call gives up after a short wait instead of macOS's six seconds.
@MainActor
public protocol WindowAccess: AnyObject {
    /// Starts watching the app with process ID `pid`, calling `onChange` when one of its windows
    /// opens, closes, moves, resizes, is minimised or comes back. Nil when the app doesn't answer yet.
    func watch(_ pid: Int32, onChange: @escaping @MainActor (WindowEvent) -> Void) -> (any WatchedApp)?
}

/// What happened to a watched app's windows.
public enum WindowEvent: Equatable, Sendable {
    /// A window opened, closed, was minimised, came back or got the focus.
    case changed
    /// A window was moved or resized.
    case moved
}

/// An app the window manager watches.
@MainActor
public protocol WatchedApp: AnyObject {
    /// The app's windows, front to back, each also watched from now on, or nil when the app
    /// doesn't answer.
    func windows() -> [any AppWindow]?
    /// Stops watching the app.
    func stop()
}

/// One window of a watched app.
@MainActor
public protocol AppWindow: AnyObject {
    /// What it says about itself.
    var facts: WindowFacts { get }
    /// Where it is, in Accessibility's coordinates, or nil when it doesn't say.
    var frame: CGRect? { get }
    /// Whether it's minimised to the Dock.
    var isMinimized: Bool { get }
    /// Moves and resizes it: size, position, then size again, since the first resize can be held
    /// back by the screen's edge until the window has moved. Done without the app's animation.
    func setFrame(_ frame: CGRect)
    /// Moves it, keeping its size.
    func setOrigin(_ origin: CGPoint)
    /// Whether `other` is this same window, read again.
    func isSame(as other: any AppWindow) -> Bool
}
