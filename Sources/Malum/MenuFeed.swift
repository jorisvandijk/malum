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
    /// Why the modules stay off because Malum isn't signed, or nil when they don't.
    var signingProblem: String? {
        didSet { refresh() }
    }

    /// Puts the icon in the menu bar and shows the state of `modules` and `config` in it, with
    /// what Run and Show log write in `output`.
    init(modules: [any Module], config: LiveConfig, output: OutputPopup) {
        self.modules = modules
        self.config = config
        self.output = output
        menuBar = MenuBar { [weak config, weak output] fix in
            guard let config, let output else { return }
            Self.perform(fix, on: config, output: output)
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
    private static func perform(_ fix: MenuFix, on config: LiveConfig, output: OutputPopup) {
        switch fix {
        case .run:
            guard !openInTerminal(Invocation.runArguments, config: config) else { return }
            Task { await output.run(OutputPopup.runLabel, work: runSystemConfig) }
        case .showLog:
            guard !openInTerminal(Invocation.logArguments(last: LogCommand.lastHour), config: config) else { return }
            Task {
                await output.run(OutputPopup.logLabel) { write in
                    await LogCommand(runner: runner).lines(last: LogCommand.lastHour).forEach(write)
                }
            }
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

    /// Opens Malum with `arguments` in a new window of the terminal that `[system_config]` names,
    /// and says whether it does. Without a terminal, or outside the app bundle, the popup shows
    /// the output instead.
    private static func openInTerminal(_ arguments: [String], config: LiveConfig) -> Bool {
        guard let executable,
            let launch = TerminalLaunch(
                settings: config.settings[SystemConfig.id], executable: executable, command: arguments,
                shell: loginShell())
        else { return false }
        Task {
            do {
                try await WorkspaceApps.openNew(launch.bundleID, arguments: launch.arguments)
            } catch {
                announce(.failed(error))
            }
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
