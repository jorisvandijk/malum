/// The window under a point on the screen, with the process ID of the app it belongs to.
@MainActor
public struct PointedWindow {
    /// The process ID of its app.
    public let pid: Int32
    /// The window.
    public let window: any AppWindow

    /// Pairs `window` with its app's process ID.
    public init(pid: Int32, window: any AppWindow) {
        self.pid = pid
        self.window = window
    }
}
