/// Accessibility's names for attributes, notifications and actions, written out because the
/// framework's constants aren't safe to read under strict concurrency.
enum AccessibilityName {
    /// What kind of element it is, such as a window.
    static let role = "AXRole"
    /// What kind of window it is, such as a dialog.
    static let subrole = "AXSubrole"
    /// A window's title.
    static let title = "AXTitle"
    /// Whether a window is modal.
    static let modal = "AXModal"
    /// A window's top left corner.
    static let position = "AXPosition"
    /// A window's size.
    static let size = "AXSize"
    /// Whether a window is in the Dock.
    static let minimized = "AXMinimized"
    /// Whether a window is in macOS's own fullscreen.
    static let fullScreen = "AXFullScreen"
    /// Set on an app by assistive tools; while it's on, the app animates every resize.
    static let enhancedUserInterface = "AXEnhancedUserInterface"
    /// An app's windows, front to back.
    static let windows = "AXWindows"
    /// Whether an app is the frontmost one.
    static let frontmost = "AXFrontmost"
    /// Whether an app is hidden.
    static let hidden = "AXHidden"
    /// Brings a window to the front of its app.
    static let raise = "AXRaise"
    /// An app opened a window.
    static let windowCreated = "AXWindowCreated"
    /// Another window of an app got the focus.
    static let focusedWindowChanged = "AXFocusedWindowChanged"
    /// A window closed.
    static let destroyed = "AXUIElementDestroyed"
    /// A window moved.
    static let moved = "AXWindowMoved"
    /// A window was resized.
    static let resized = "AXWindowResized"
    /// A window went to the Dock.
    static let minimizedNotification = "AXWindowMiniaturized"
    /// A window came back from the Dock.
    static let restored = "AXWindowDeminiaturized"
}
