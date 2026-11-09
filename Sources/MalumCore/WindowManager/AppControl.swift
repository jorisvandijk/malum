/// Running, raising and hiding apps, for the window manager. `WorkspaceApps` in MalumPlatform is the
/// real one.
@MainActor
public protocol AppControl: AnyObject {
    /// The running app with `bundleID`, or nil when it isn't running.
    func running(_ bundleID: String) -> RunningApp?
    /// Every ordinary app that runs and isn't hidden.
    func visibleApps() -> [RunningApp]
    /// What `app`'s windows look like.
    func windows(of app: RunningApp) -> AppWindowsState
    /// Opens the app with `bundleID`: starts it, or asks a running one for a new window.
    func open(_ bundleID: String) async throws(WindowManagerError)
    /// Shows `app` when it's hidden.
    func unhide(_ app: RunningApp)
    /// Brings `app` to the front.
    func activate(_ app: RunningApp)
    /// Brings back `app`'s most recently minimised window.
    func unminimize(_ app: RunningApp)
    /// Hides `app`, and says whether it worked.
    func hide(_ app: RunningApp) -> Bool
}
