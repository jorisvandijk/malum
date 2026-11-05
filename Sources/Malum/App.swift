import AppKit
import MalumCore
import MalumPlatform

/// Runs Malum as the menu bar app, or quits straight away when another app already runs.
@MainActor
func runApp() -> Never {
    let instance = AppInstance(state: state, locks: locks)
    do {
        guard try instance.claim(processID: getpid()) else {
            announce(.alreadyRunning)
            // launchd starts the login agent again after a failure, so a freshly signed app that
            // launchd starts while the old one is still quitting gets another go once it's gone.
            exit(
                LaunchMode.isLoginAgent(environment: ProcessInfo.processInfo.environment) ? EXIT_FAILURE : EXIT_SUCCESS)
        }
    } catch {
        announce(.failed(error))
        exit(EXIT_FAILURE)
    }
    announce(.running)
    updateLoginAgent()
    let launches = LaunchRecord(state: state)
    checkCrashLoop(launches, overrides: OverrideStore(state: state))
    // TODO: one list of the modules, which MalumDocs shares, once there are modules.
    let modules: [any Module] = []
    let schemas = ConfigSchemas.all(modules: modules)
    let config = LiveConfig(
        reloader: ConfigReloader(files: files, paths: paths, schemas: schemas),
        modules: ModuleSwitch(modules: modules, permissions: PermissionProbe(home: paths.home)),
        overrides: OverrideStore(state: state))
    let menu = MenuFeed(modules: modules, config: config)
    config.start()
    Task { await startWhenSigned(config: config, menu: menu) }
    let hangup = HangupWatcher { config.reload(force: true) }
    let quit = NotificationCenter.default.addObserver(
        forName: NSApplication.willTerminateNotification, object: nil, queue: .main
    ) { _ in MainActor.assumeIsolated { forget(launches) } }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    withExtendedLifetime((menu, config, hangup, quit)) { app.run() }
    exit(EXIT_SUCCESS)
}

/// Lets the modules start once the installed app is signed with Malum's own certificate. A new
/// install is signed in place first, and started again through launchd as the signed app.
@MainActor
private func startWhenSigned(config: LiveConfig, menu: MenuFeed) async {
    let certificate = SigningCertificate(
        runner: runner, files: files, paths: paths, temporaryDirectory: NSTemporaryDirectory())
    let signing = SelfSigning(runner: runner, files: files, paths: paths, certificate: certificate)
    switch await signing.check(executable: executable) {
    case .signed:
        config.allowModules()
    case .resigned:
        announce(.resigned)
        do {
            try await signing.restart(userID: getuid())
            exit(EXIT_SUCCESS)
        } catch {
            refuse(.warning(error), menu: menu)
        }
    case .notInstalled:
        refuse(.modulesOff(installed: paths.installedBundle), menu: menu)
    case .failed(let error):
        refuse(.warning(error), menu: menu)
    }
}

/// Keeps the modules off because Malum isn't signed, and says why in the log and the menu.
@MainActor
private func refuse(_ problem: Message, menu: MenuFeed) {
    announce(problem)
    menu.signingProblem = problem.text.description
}

/// Writes down this start, and turns safe mode on when Malum keeps starting, as it does when it
/// crashes at every start.
@MainActor
private func checkCrashLoop(_ launches: LaunchRecord, overrides: OverrideStore) {
    do {
        guard try launches.record(at: Int(Date().timeIntervalSince1970)) else { return }
        try overrides.enterSafeMode(.crashLoop)
        announce(.crashLoop)
    } catch {
        announce(.warning(error))
    }
}

/// Forgets the recent starts when the user quits, so quitting and opening again isn't taken for a crash.
@MainActor
private func forget(_ launches: LaunchRecord) {
    do {
        try launches.clear()
    } catch {
        announce(.warning(error))
    }
}

/// Writes the login agent when the installed app starts and the agent is missing or differs.
@MainActor
private func updateLoginAgent() {
    do {
        switch try LoginAgent(files: files, paths: paths).update(executable: executable) {
        case .written:
            announce(.startsAtLogin(through: paths.loginAgent))
        case .unchanged:
            break
        case .notInstalled:
            announce(.notStartingAtLogin(installed: paths.installedExecutable))
        }
    } catch {
        announce(.warning(error))
    }
}
