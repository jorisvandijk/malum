import AppKit
import MalumCore
import MalumPlatform

/// Runs Malum as the menu bar app, or quits straight away when another app already runs.
@MainActor
func runApp() -> Never {
    let instance = AppInstance(state: StateFolder(files: files, locks: locks, paths: paths), locks: locks)
    do {
        guard try instance.claim(processID: getpid()) else {
            announce(Message(.info, "\(Project.name) is already running"))
            exit(EXIT_SUCCESS)
        }
    } catch {
        announce(Message(.error, error.text))
        exit(EXIT_FAILURE)
    }
    announce(Message(.info, "\(Project.name) \(Project.version) is running"))
    updateLoginAgent()
    let state = StateFolder(files: files, locks: locks, paths: paths)
    let launches = LaunchRecord(state: state)
    checkCrashLoop(launches, overrides: OverrideStore(state: state))
    // TODO: one list of the modules, whose schemas MalumDocs shares, once there are modules.
    let modules: [any Module] = []
    let schemas = Dictionary(modules.map { ($0.id, $0.schema) }) { first, _ in first }
    let config = LiveConfig(
        reloader: ConfigReloader(files: files, paths: paths, schemas: schemas), modules: ModuleSwitch(modules: modules),
        overrides: OverrideStore(state: state))
    let menu = MenuFeed(modules: modules, config: config)
    config.start()
    let hangup = HangupWatcher { config.reload(force: true) }
    let quit = NotificationCenter.default.addObserver(
        forName: NSApplication.willTerminateNotification, object: nil, queue: .main
    ) { _ in MainActor.assumeIsolated { forget(launches) } }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    withExtendedLifetime((menu, config, hangup, quit)) { app.run() }
    exit(EXIT_SUCCESS)
}

/// Writes down this start, and turns safe mode on when Malum keeps starting, as it does when it
/// crashes at every start.
@MainActor
private func checkCrashLoop(_ launches: LaunchRecord, overrides: OverrideStore) {
    do {
        guard try launches.record(at: Int(Date().timeIntervalSince1970)) else { return }
        try overrides.enterSafeMode(.crashLoop)
        announce(Message(.warn, "\(SafeModeReason.crashLoop), so safe mode is on and every module stays off"))
    } catch {
        announce(Message(.warn, error.text))
    }
}

/// Forgets the recent starts when the user quits, so quitting and opening again isn't taken for a crash.
@MainActor
private func forget(_ launches: LaunchRecord) {
    do {
        try launches.clear()
    } catch {
        announce(Message(.warn, error.text))
    }
}

/// Writes the login agent when the installed app starts and the agent is missing or differs.
@MainActor
private func updateLoginAgent() {
    do {
        switch try LoginAgent(files: files, paths: paths).update(executable: executable) {
        case .written:
            announce(Message(.info, "\(Project.name) starts at login, through \(private: paths.loginAgent)"))
        case .unchanged:
            break
        case .notInstalled:
            let installed = paths.installedExecutable
            announce(Message(.info, "not starting at login: \(Project.name) isn't running from \(private: installed)"))
        }
    } catch {
        announce(Message(.warn, error.text))
    }
}
