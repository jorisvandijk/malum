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
        HotkeyOffer(fixedKeys: config.blocksHideMinimize ? Self.blockedKeys : [:], opensApps: true)
    }
    /// Where the module is now.
    private(set) var status = ModuleStatus.off

    /// What it works through in macOS.
    @ObservationIgnored private let system: WindowManagerSystem
    /// Runs and raises apps, and hides the others.
    @ObservationIgnored private let runRaise: RunRaise
    /// The module's own log.
    @ObservationIgnored private let log: Log
    /// The settings last given.
    @ObservationIgnored private var config = WindowManagerConfig()
    /// One tracker for each app whose windows it fills the screen with, by process ID.
    @ObservationIgnored private var trackers: [Int32: AppTracker] = [:]
    /// Whether the module runs, so a late look at an app doesn't start tracking it after a stop.
    @ObservationIgnored private var isStarted = false
    /// The last app raised for a shortcut, which tests wait for.
    @ObservationIgnored private(set) var raising: Task<Void, Never>?

    /// Creates the module, off, working through `system` and logging to `log`.
    init(system: WindowManagerSystem, log: Log) {
        self.system = system
        self.log = log.module(WindowManagerConfig.module)
        runRaise = RunRaise(apps: system.apps, log: self.log)
    }

    /// Nothing to undo: the window manager changes nothing that outlives Malum.
    func cleanUp() async throws {}

    /// Takes new settings, and lays the windows out again by them when the module runs.
    func apply(_ settings: ModuleSettings) {
        // The config only hands over settings that read without errors, so nothing is reported.
        config = WindowManagerConfig.read(settings.table) { _, _ in }
        for tracker in trackers.values {
            tracker.config = config
            tracker.area = area
            tracker.reconcile()
        }
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

    /// Starts the app a shortcut names, or brings it into view. A swallowed key does nothing.
    func perform(_ action: KeyAction) {
        guard case .app(let bundleID) = action else { return }
        raising = Task { [runRaise] in await runRaise.raise(bundleID) }
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
