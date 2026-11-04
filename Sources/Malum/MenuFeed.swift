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

    /// Puts the icon in the menu bar and shows the state of `modules` and `config` in it.
    init(modules: [any Module], config: LiveConfig) {
        self.modules = modules
        self.config = config
        menuBar = MenuBar { [weak config] in config?.reload(force: true) }
        config.onUpdate = { [weak self] in self?.refresh() }
        refresh()
        observeModules()
    }

    /// Shows the current state in the menu.
    func refresh() {
        let path = config.path
        let menu = StatusMenu(
            modules: modules.map { (id: $0.id, status: $0.status) }, report: config.report, configPath: path,
            configExists: path.map { files.item(at: $0) != nil } ?? false)
        menuBar.show(menu)
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
