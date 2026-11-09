/// Why the window manager couldn't do its work.
public enum WindowManagerError: Error, Equatable, Sendable {
    /// No app with this bundle ID is installed.
    case notInstalled(String)
    /// macOS didn't open the app with this bundle ID, for this reason.
    case openFailed(String, reason: String)
}
