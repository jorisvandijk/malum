/// What the window manager works through in macOS: apps, their windows and the screen. The app
/// builds the real ones; tests hand in fakes.
@MainActor
public struct WindowManagerSystem {
    /// Runs, raises and hides apps.
    let apps: any AppControl
    /// Reaches app windows through Accessibility.
    let windows: any WindowAccess
    /// Tells which apps run, and what happens to them.
    let watcher: any AppWatcher
    /// Tells about the screen.
    let screens: any Screens
    /// Runs the later looks at windows and apps.
    let scheduler: any WindowScheduler

    /// Gathers the parts the window manager needs.
    public init(apps: any AppControl, windows: any WindowAccess, watcher: any AppWatcher, screens: any Screens) {
        self.init(apps: apps, windows: windows, watcher: watcher, screens: screens, scheduler: TaskScheduler())
    }

    /// Gathers the parts, with a `scheduler` the tests run by hand.
    init(
        apps: any AppControl, windows: any WindowAccess, watcher: any AppWatcher, screens: any Screens,
        scheduler: any WindowScheduler
    ) {
        self.apps = apps
        self.windows = windows
        self.watcher = watcher
        self.screens = screens
        self.scheduler = scheduler
    }
}
