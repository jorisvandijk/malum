/// Something that happened to a running app, which the window manager reacts to.
public enum AppEvent: Equatable, Sendable {
    /// The app started.
    case launched(RunningApp)
    /// The app with this process ID quit.
    case terminated(Int32)
    /// The app came to the front.
    case activated(RunningApp)
    /// The app with this process ID was shown again after being hidden.
    case unhidden(Int32)
    /// A screen was plugged in, unplugged, rearranged or resized, or the Dock moved.
    case screensChanged
}
