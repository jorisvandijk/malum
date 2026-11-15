import Darwin
import MalumCore
import MalumPlatform
import Observation

/// The shell a terminal window runs commands through when the user's own can't be found.
private let fallbackShell = "/bin/zsh"

/// Keeps the menu bar icon up to date with the modules and the config.
@MainActor
final class MenuFeed {
    /// The icon and its menu.
    private let menuBar: MenuBar
    /// Every module, in the order the menu lists them.
    private let modules: [any Module]
    /// The config, which says what its last load found.
    private let config: LiveConfig
    /// Shows what Run and Show log write.
    private let output: OutputPopup
    /// Where Inspect window goes, and how a terminal is raised: the window manager, while it runs.
    private let routes: ModuleRoutes
    /// Why the modules stay off because Malum isn't signed, or nil when they don't.
    var signingProblem: String? {
        didSet { refresh() }
    }

    /// Puts the icon in the menu bar and shows the state of `modules` and `config` in it, with
    /// what Run and Show log write in `output`, and Inspect window run through `routes`.
    init(modules: [any Module], config: LiveConfig, output: OutputPopup, routes: ModuleRoutes) {
        self.modules = modules
        self.config = config
        self.output = output
        self.routes = routes
        menuBar = MenuBar { [weak config, weak output, weak routes] fix in
            guard let config, let output, let routes else { return }
            Self.perform(fix, on: config, output: output, routes: routes)
        }
        config.onUpdate = { [weak self] in self?.refresh() }
        config.onRestart = { messages, running in
            let notice = ReloadNotice(messages: messages, running: running)
            Task {
                let shown = await Notifier().show(title: notice.title, body: notice.body)
                if !shown {
                    announce(.notificationsOff)
                }
            }
        }
        refresh()
        observeModules()
    }

    /// Shows the current state in the menu.
    func refresh() {
        let path = config.path
        let menu = StatusMenu(
            modules: modules.map { (id: $0.id, status: status(of: $0)) }, report: config.report, configPath: path,
            configExists: path.map { files.item(at: $0) != nil } ?? false, overrides: config.overrides,
            signingProblem: signingProblem)
        menuBar.show(menu)
    }

    /// The module's status, or the permissions it waits for when it can't start without them.
    private func status(of module: any Module) -> ModuleStatus {
        config.waiting[module.id].map(ModuleStatus.needsPermission) ?? module.status
    }

    /// Does what a picked item asks of the app.
    private static func perform(_ fix: MenuFix, on config: LiveConfig, output: OutputPopup, routes: ModuleRoutes) {
        switch fix {
        case .run:
            run(config: config, output: output, routes: routes)
        case .runAction(let action):
            guard !routes.run(actionNamed: action) else { return }
            announce(.noModuleFor(action))
        case .showLog:
            showLog(config: config, output: output, routes: routes)
        case .reload:
            config.restart()
        case .leaveSafeMode:
            config.change { store throws(StateError) in try store.leaveSafeMode() }
        case .enable(let module):
            config.change { store throws(StateError) in try store.enable(module) }
        case .quit:
            stopAndQuit(config)
        case .openFile, .showFolder, .openSettings, .about:
            break  // MenuBar does these itself.
        }
    }

    /// Runs system config in the terminal, or in the popup when there's none.
    private static func run(config: LiveConfig, output: OutputPopup, routes: ModuleRoutes) {
        guard !openInTerminal(Invocation.runArguments, config: config, routes: routes) else { return }
        Task { await output.run(OutputPopup.runLabel, work: runSystemConfig) }
    }

    /// Shows the log of the last hour in the terminal, or in the popup when there's none.
    private static func showLog(config: LiveConfig, output: OutputPopup, routes: ModuleRoutes) {
        let arguments = Invocation.logArguments(last: LogCommand.lastHour)
        guard !openInTerminal(arguments, config: config, routes: routes) else { return }
        Task {
            await output.run(OutputPopup.logLabel) { write in
                await LogCommand(runner: runner).lines(last: LogCommand.lastHour).forEach(write)
            }
        }
    }

    /// Opens Malum with `arguments` in the terminal that `[system_config]` names, and says whether
    /// one does. Without a terminal, or outside the app bundle, the popup shows the output instead.
    private static func openInTerminal(_ arguments: [String], config: LiveConfig, routes: ModuleRoutes) -> Bool {
        guard let executable,
            let launch = TerminalLaunch(
                settings: config.settings[SystemConfig.id], executable: executable, command: arguments,
                shell: loginShell())
        else { return false }
        Task {
            let tabbed = await openTab(launch, routes: routes)
            guard !tabbed else { return }
            do {
                try await WorkspaceApps.openNew(launch.bundleID, arguments: launch.arguments)
            } catch {
                announce(.failed(error))
            }
        }
        return true
    }

    /// Opens `launch` as a new tab in the kitty that runs and listens on its socket, then raises
    /// kitty as its key would. Says whether it did; otherwise a new window opens instead.
    private static func openTab(_ launch: TerminalLaunch, routes: ModuleRoutes) async -> Bool {
        guard launch.bundleID == Kitten.bundleID,
            let kitty = WorkspaceApps().running(launch.bundleID),
            let app = WorkspaceAppHandlers().app(launch.bundleID)
        else { return false }
        let socket = Kitten.socket(processID: kitty.pid)
        guard files.item(at: socket) != nil else { return false }
        let result = await runner.run(Kitten.newTab(app: app.path, socket: socket, program: launch.program))
        guard result.succeeded else {
            announce(.tabFailed(reason: result.reason))
            return false
        }
        guard !routes.openApp(launch.bundleID) else { return true }
        do {
            try await WorkspaceApps().open(launch.bundleID)
        } catch {
            announce(.failed(error))
        }
        return true
    }

    /// Refreshes the menu each time a module's status changes.
    private func observeModules() {
        withObservationTracking {
            _ = modules.map(\.status)
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.refresh()
                self?.observeModules()
            }
        }
    }
}

/// Runs system config as `malum run` does, without asking for the password or updating Malum,
/// writing what it reports to `write` and to the log.
@MainActor
private func runSystemConfig(_ write: @MainActor (String) -> Void) async {
    _ = await systemConfig(canAsk: false, github: gitHub()).run { message in
        announce(message)
        write(message.description)
    }
}

/// The user's login shell, as the user database names it.
private func loginShell() -> String {
    guard let entry = getpwuid(getuid()), let shell = entry.pointee.pw_shell else { return fallbackShell }
    return String(cString: shell)
}
