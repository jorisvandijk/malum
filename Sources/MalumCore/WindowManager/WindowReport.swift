import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// What the window inspector found out about one window.
struct WindowReport: Equatable, Sendable {
    /// What the window manager does with a window.
    enum Handling: Equatable, Sendable {
        /// It's managed or floats, as the window manager decided.
        case kind(WindowKind)
        /// The window manager doesn't track its app, which only runs in the menu bar or in the
        /// background, so it leaves all the app's windows alone.
        case appNotTracked
    }

    /// Its app's name, or nil when the app isn't one Malum knows.
    let app: String?
    /// Its app's bundle ID, or nil when it has none.
    let bundleID: String?
    /// What it says about itself.
    let facts: WindowFacts
    /// Where it is, in Accessibility's coordinates, or nil when it doesn't say.
    let frame: CGRect?
    /// The shortcuts that raise its app, its workspace keys.
    let keys: [Hotkey]
    /// What the window manager does with it.
    let handling: Handling
}
