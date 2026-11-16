import Foundation
import Observation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// The window manager module: run or raise for the app shortcuts in `keyboard.toml`, the other apps
/// hidden when one comes to the front, and every app's windows filling the screen.
@Observable
@MainActor
final class WindowManagerModule: Module {
    /// How many times an app that doesn't answer Accessibility yet, as just after it starts, is
    /// looked at again.
    private static let watchTries = 10
    /// How long to wait before looking again, so all tries take about two seconds.
    private static let watchDelayMilliseconds = 200
    /// How long to wait after the screens change before laying the windows out again, since macOS
    /// sends a burst of changes while a display comes and goes.
    private static let settleMilliseconds = 500
    /// The action that lets the user click a window and shows what it is, for `keyboard.toml` and
    /// the menu.
    public static let inspectAction = WindowManagerConfig.inspectAction
    /// The action that floats the focused window, or puts it back in its place, for `keyboard.toml`.
    public static let toggleFloatAction = WindowManagerConfig.toggleFloatAction
    /// The action of the keys it swallows, which isn't offered to `keyboard.toml`.
    private static let blockAction = "block"
    /// cmd+H, cmd+M and cmd+option+M, which hide the app or minimise windows, for
    /// `block_hide_minimize`. Hidden apps and minimised windows would leave a gap in the layout.
    private static let blockedKeys: [Hotkey: String] = Dictionary(
        uniqueKeysWithValues: [("h", [Modifier.cmd]), ("m", [.cmd]), ("m", [.cmd, .option])].compactMap {
            name, modifiers in
            Key.named(name).map { (Hotkey(modifiers: Set(modifiers), key: $0), blockAction) }
        })

    /// The module's id, which names `window_manager.toml`.
    let id = WindowManagerConfig.module
    /// Moving other apps' windows needs Accessibility, and nothing else.
    let permissions: Set<Permission> = [.accessibility]
    /// Its settings.
    var schema: ConfigSchema { WindowManagerConfig.schema }
    /// It opens the apps the shortcuts in `keyboard.toml` name, and swallows the keys that hide and
    /// minimise when `block_hide_minimize` is on.
    var hotkeys: HotkeyOffer {
        HotkeyOffer(
            actions: [Self.inspectAction, Self.toggleFloatAction],
            fixedKeys: config.blocksHideMinimize ? Self.blockedKeys : [:], opensApps: true)
    }
    /// Where the module is now.
    private(set) var status = ModuleStatus.off

    /// What it works through in macOS.
    @ObservationIgnored private let system: WindowManagerSystem
    /// Runs and raises apps, and hides the others.
    @ObservationIgnored private let runRaise: RunRaise
    /// Shows what a clicked window is.
    @ObservationIgnored private let inspector: WindowInspector
    /// Where the workspace keys of each app come from.
    @ObservationIgnored private let routes: ModuleRoutes
    /// The module's own log.
    @ObservationIgnored private let log: Log
    /// The settings last given.
    @ObservationIgnored private var config = WindowManagerConfig()
    /// One tracker for each app whose windows it fills the screen with, by process ID.
    @ObservationIgnored private var trackers: [Int32: AppTracker] = [:]
    /// Whether the module runs, so a late look at an app doesn't start tracking it after a stop.
    @ObservationIgnored private var isStarted = false
    /// Whether laying the windows out again after a change to the screens is waiting.
    @ObservationIgnored private var isLayoutPending = false
    /// The last app raised for a shortcut, or the last window inspected, which tests wait for.
    @ObservationIgnored private(set) var raising: Task<Void, Never>?

    /// Creates the module, off, working through `system`, reading workspace keys from `routes` and
    /// logging to `log`.
    init(system: WindowManagerSystem, routes: ModuleRoutes, log: Log) {
        self.system = system
        self.routes = routes
        self.log = log.module(WindowManagerConfig.module)
        runRaise = RunRaise(apps: system.apps, scheduler: system.scheduler, log: self.log)
        inspector = WindowInspector(
            windows: system.windows, watcher: system.watcher, system: system.inspector, log: self.log)
    }

    /// Nothing to undo: the window manager changes nothing that outlives Malum.
    func cleanUp() async throws {}

    /// Takes new settings, and lays the windows out again by them when the module runs.
    func apply(_ settings: ModuleSettings) {
        // The config only hands over settings that read without errors, so nothing is reported.
        config = WindowManagerConfig.read(settings.table) { _, _ in }
        for tracker in trackers.values {
            tracker.config = config
        }
        layOutAgain()
    }

    /// Starts following the apps, and fills the screen with the windows of those that run.
    func start() async throws {
        status = .starting
        isStarted = true
        system.watcher.start { [weak self] event in self?.handle(event) }
        for app in system.watcher.runningApps() {
            track(app)
        }
        status = .running
    }

    /// Stops following the apps, and leaves their windows where they are.
    func stop() async {
        isStarted = false
        system.watcher.stop()
        for tracker in trackers.values {
            tracker.stop()
        }
        trackers = [:]
        status = .off
    }

    /// Lays the windows out again after the Mac wakes or the user switches back to this login, since
    /// macOS may have moved them, or the screen may have changed meanwhile.
    func resume() async {
        layOutAgain()
    }

    /// Starts the app a shortcut names, or brings it into view, inspects a window, or floats the
    /// focused one or puts it back. A swallowed key does nothing.
    func perform(_ action: KeyAction) {
        switch action {
        case .app(let bundleID):
            raising = Task { [runRaise] in await runRaise.raise(bundleID) }
        case .module(Self.inspectAction):
            raising = Task { [weak self] in await self?.inspect() }
        case .module(Self.toggleFloatAction):
            toggleFloat()
        case .module:
            return
        }
    }

    /// Lets the user click a window and shows what it is.
    private func inspect() async {
        await inspector.inspect(keys: routes.appKeys, handling: handling(of:app:))
    }

    /// Floats the focused window of the app in front, or puts it back in its place when it was
    /// floated this way.
    private func toggleFloat() {
        guard let front = system.apps.visibleApps().first(where: \.isActive), let tracker = trackers[front.pid]
        else { return }
        tracker.toggleFloat()
    }

    /// What the module does with `pointed`, a window of `app`: what its tracker decided, or what it
    /// would decide when the tracker hasn't seen the window yet.
    private func handling(of pointed: PointedWindow, app: RunningApp?) -> WindowReport.Handling {
        guard let tracker = trackers[pointed.pid] else { return .appNotTracked }
        let kind =
            tracker.kind(of: pointed.window)
            ?? WindowLayout.classify(pointed.window.facts, app: app?.bundleID, floats: config.floats)
        return .kind(kind)
    }

    /// The part of the screen windows fill now, or nil when there's no screen.
    private var area: CGRect? {
        system.screens.main()?.area(config.frame)
    }

    /// Reacts to what happened to an app.
    private func handle(_ event: AppEvent) {
        switch event {
        case .launched(let app):
            track(app)
        case .terminated(let pid):
            trackers.removeValue(forKey: pid)?.stop()
        case .activated(let app):
            runRaise.hideOthers(except: app, config: config)
        case .unhidden(let pid):
            trackers[pid]?.reconcile()
        case .screensChanged:
            layOutOnceSettled()
        }
    }

    /// Lays the windows out again once a burst of changes to the screens has passed.
    private func layOutOnceSettled() {
        guard !isLayoutPending else { return }
        isLayoutPending = true
        system.scheduler.after(.milliseconds(Self.settleMilliseconds)) { [weak self] in
            self?.isLayoutPending = false
            self?.layOutAgain()
        }
    }

    /// Fills the screen as it is now with every app's windows. With no screen, windows stay put.
    private func layOutAgain() {
        let area = area
        for tracker in trackers.values {
            tracker.area = area
            tracker.reconcile()
        }
    }

    /// Starts filling the screen with `app`'s windows. An app that doesn't answer yet is looked at
    /// again a few times, since a starting app answers Accessibility only once it's ready.
    private func track(_ app: RunningApp, try number: Int = 1) {
        guard isStarted, app.isRegular, trackers[app.pid] == nil else { return }
        let pid = app.pid
        let watched = system.windows.watch(pid) { [weak self] event in self?.trackers[pid]?.handle(event) }
        guard let watched else {
            guard number < Self.watchTries else { return }
            system.scheduler.after(.milliseconds(Self.watchDelayMilliseconds)) { [weak self] in
                self?.track(app, try: number + 1)
            }
            return
        }
        let tracker = AppTracker(
            app: app, watched: watched, access: system.windows, scheduler: system.scheduler, log: log)
        tracker.config = config
        tracker.area = area
        trackers[pid] = tracker
        tracker.reconcile()
    }
}
