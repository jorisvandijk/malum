/// One step that brings an app into view.
enum RaiseStep: Equatable, Sendable {
    /// Start the app.
    case launch
    /// Show the hidden app.
    case unhide
    /// Bring it to the front.
    case activate
    /// Open it again while it runs, as a click on its Dock icon does, so it makes a new window.
    case reopen
    /// Bring back its most recently minimised window.
    case unminimize
}
