import MalumCore
import MalumPlatform
import Observation

/// Keeps the menu bar icon up to date with the modules and the config.
@MainActor
final class MenuFeed {
    /// The icon and its menu.
    private let menuBar: MenuBar
    /// Every module, in the order the menu lists them.
    private let modules: [any Module]
    /// The config, which says what its last load found.
    private let config: LiveConfig
    /// Why the modules stay off because Malum isn't signed, or nil when they don't.
    var signingProblem: String? {
        didSet { refresh() }
    }

    /// Puts the icon in the menu bar and shows the state of `modules` and `config` in it.
    init(modules: [any Module], config: LiveConfig) {
        self.modules = modules
        self.config = config
        menuBar = MenuBar { [weak config] fix in
            guard let config else { return }
            Self.perform(fix, on: config)
        }
        config.onUpdate = { [weak self] in self?.refresh() }
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
    private static func perform(_ fix: MenuFix, on config: LiveConfig) {
        switch fix {
        case .reload:
            config.reload(force: true)
        case .leaveSafeMode:
            config.change { store throws(StateError) in try store.leaveSafeMode() }
        case .enable(let module):
            config.change { store throws(StateError) in try store.enable(module) }
        case .openFile, .showFolder, .openSettings, .quit:
            break  // MenuBar does these itself.
        }
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
