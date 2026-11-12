/// Run or raise: starts an app, or brings it into view alone, and hides the others whenever an app
/// comes to the front.
///
/// macOS sometimes turns down a switch while the app that was in front is still letting go, so a
/// raise that didn't take and a hide that didn't work are tried again a moment later.
@MainActor
final class RunRaise {
    /// How many times a raise or a hide is tried before giving up.
    private static let tries = 4
    /// How long to wait before trying again, in milliseconds.
    private static let retryDelayMilliseconds = 150

    /// Runs, raises and hides apps.
    private let apps: any AppControl
    /// Waits before trying again.
    private let scheduler: any WindowScheduler
    /// The window manager's log.
    private let log: Log
    /// The app the latest shortcut asked for, so an older raise stops trying once there's a newer one.
    private var latest: String?

    /// Creates run or raise, working through `apps`, trying again through `scheduler` and logging to `log`.
    init(apps: any AppControl, scheduler: any WindowScheduler, log: Log) {
        self.apps = apps
        self.scheduler = scheduler
        self.log = log
    }

    /// The steps that bring `app` into view, or `.launch` when it doesn't run. None when it's already
    /// in view, so pressing its key again does nothing.
    static func steps(for app: RunningApp?, windows: AppWindowsState) -> [RaiseStep] {
        guard let app else { return [.launch] }
        var steps: [RaiseStep] = []
        if app.isHidden {
            steps.append(.unhide)
        }
        if app.isHidden || !app.isActive {
            steps.append(.activate)
        }
        switch windows {
        case .noWindows:
            steps.append(.reopen)
        case .onlyMinimized:
            steps.append(.unminimize)
        case .some, .unknown:
            break
        }
        return steps
    }

    /// Whether the others are hidden when `app` comes to the front. Apps without a Dock icon and apps
    /// that float as a whole in `config` hide nothing.
    static func hidesOthers(for app: RunningApp, config: WindowManagerConfig) -> Bool {
        guard app.isRegular else { return false }
        return !config.floats.contains { $0.app == app.bundleID && $0.title == nil }
    }

    /// Starts the app with `bundleID`, or brings it into view.
    func raise(_ bundleID: String) async {
        latest = bundleID
        let app = apps.running(bundleID)
        let steps = Self.steps(for: app, windows: app.map(apps.windows) ?? .unknown)
        for step in steps {
            await take(step, for: app, bundleID: bundleID)
        }
        if steps.contains(.activate) {
            checkRaised(bundleID, try: 1)
        }
    }

    /// Hides every other visible app when `config` asks for it, for `active`, which just came to the front.
    func hideOthers(except active: RunningApp, config: WindowManagerConfig) {
        guard Self.hidesOthers(for: active, config: config) else { return }
        hide(apps.visibleApps().filter { $0.pid != active.pid }, for: active, try: 1)
    }

    /// Hides `others`, and tries the ones that stay in view again while `active` is still in front.
    private func hide(_ others: [RunningApp], for active: RunningApp, try number: Int) {
        let failed = others.filter { !apps.hide($0) }
        guard !failed.isEmpty else { return }
        guard number < Self.tries else {
            log.report(.couldntHide(failed.map(\.name)))
            return
        }
        scheduler.after(.milliseconds(Self.retryDelayMilliseconds)) { [weak self] in
            guard let self else { return }
            let visible = apps.visibleApps()
            guard visible.contains(where: { $0.pid == active.pid && $0.isActive }) else { return }
            let failedPIDs = Set(failed.map(\.pid))
            hide(visible.filter { failedPIDs.contains($0.pid) }, for: active, try: number + 1)
        }
    }

    /// Brings the app with `bundleID` to the front again when the switch didn't take, unless a newer
    /// shortcut asked for another app meanwhile.
    private func checkRaised(_ bundleID: String, try number: Int) {
        scheduler.after(.milliseconds(Self.retryDelayMilliseconds)) { [weak self] in
            guard let self, latest == bundleID, let app = apps.running(bundleID), !app.isActive else { return }
            guard number < Self.tries else {
                log.report(.couldntRaise(app.name))
                return
            }
            if app.isHidden {
                apps.unhide(app)
            }
            apps.activate(app)
            checkRaised(bundleID, try: number + 1)
        }
    }

    /// Takes one step for `app`, or for the app with `bundleID` when it doesn't run.
    private func take(_ step: RaiseStep, for app: RunningApp?, bundleID: String) async {
        guard let app, step != .launch else {
            await open(bundleID)
            return
        }
        switch step {
        case .unhide:
            apps.unhide(app)
        case .activate:
            apps.activate(app)
        case .unminimize:
            apps.unminimize(app)
        case .launch, .reopen:
            await open(bundleID)
        }
    }

    /// Opens the app with `bundleID`, logging when that fails.
    private func open(_ bundleID: String) async {
        do {
            try await apps.open(bundleID)
        } catch {
            log.report(.failed(error))
        }
    }
}
