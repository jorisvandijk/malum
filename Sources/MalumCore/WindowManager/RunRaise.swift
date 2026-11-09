/// Run or raise: starts an app, or brings it into view alone, and hides the others whenever an app
/// comes to the front.
@MainActor
final class RunRaise {
    /// Runs, raises and hides apps.
    private let apps: any AppControl
    /// The window manager's log.
    private let log: Log

    /// Creates run or raise, working through `apps` and logging to `log`.
    init(apps: any AppControl, log: Log) {
        self.apps = apps
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

    /// Whether `config` has the others hidden when `app` comes to the front. Apps without a Dock icon
    /// and apps that float as a whole hide nothing.
    static func hidesOthers(for app: RunningApp, config: WindowManagerConfig) -> Bool {
        guard config.hidesOthers, app.isRegular else { return false }
        return !config.floats.contains { $0.app == app.bundleID && $0.title == nil }
    }

    /// Starts the app with `bundleID`, or brings it into view.
    func raise(_ bundleID: String) async {
        let app = apps.running(bundleID)
        let steps = Self.steps(for: app, windows: app.map(apps.windows) ?? .unknown)
        for step in steps {
            await take(step, for: app, bundleID: bundleID)
        }
    }

    /// Hides every other visible app when `config` asks for it, for `active`, which just came to the front.
    func hideOthers(except active: RunningApp, config: WindowManagerConfig) {
        guard Self.hidesOthers(for: active, config: config) else { return }
        let others = apps.visibleApps().filter { $0.pid != active.pid }
        let failed = others.filter { !apps.hide($0) }.map(\.name)
        if !failed.isEmpty {
            log.report(.couldntHide(failed))
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
