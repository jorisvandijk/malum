/// Tells the window manager which apps run, and what happens to them. `WorkspaceAppWatcher` in
/// MalumPlatform is the real one.
@MainActor
public protocol AppWatcher: AnyObject {
    /// Every app that runs now.
    func runningApps() -> [RunningApp]
    /// Sends each launch, quit, activation and unhide to `onEvent` until `stop` is called.
    func start(_ onEvent: @escaping @MainActor @Sendable (AppEvent) -> Void)
    /// Stops sending events.
    func stop()
}
