import Observation

/// The launcher: its action opens the popup on every app, and picking one starts or raises it the
/// way its shortcut in `keyboard.toml` would.
@Observable
@MainActor
final class LauncherModule: Module {
    /// The module's id, which is also its action in `keyboard.toml`.
    static let module = "launcher"
    /// Its settings: none beyond switching it on.
    static let configSchema = ConfigSchema(
        about: "A popup with every app, to search and start one. See [launcher](launcher.md).", settings: [:])

    /// The module's id.
    let id = LauncherModule.module
    /// Showing a popup and opening apps need no permission.
    let permissions: Set<Permission> = []
    /// Its settings.
    var schema: ConfigSchema { Self.configSchema }
    /// It offers one action, `launcher`, which opens the popup.
    var hotkeys: HotkeyOffer { HotkeyOffer(actions: [Self.module]) }
    /// Where the module is now.
    private(set) var status = ModuleStatus.off

    /// What it works through.
    @ObservationIgnored private let system: LauncherSystem
    /// Where an app goes to be opened by the module that opens apps.
    @ObservationIgnored private let routes: ModuleRoutes
    /// The module's own log.
    @ObservationIgnored private let log: Log
    /// The apps in the popup.
    @ObservationIgnored private var list: LauncherList?
    /// The last app opened without the window manager, which tests wait for.
    @ObservationIgnored private(set) var opening: Task<Void, Never>?

    /// Creates the module, off.
    init(system: LauncherSystem, routes: ModuleRoutes, log: Log) {
        self.system = system
        self.routes = routes
        self.log = log.module(Self.module)
    }

    /// Nothing to undo: the launcher changes nothing that outlives Malum.
    func cleanUp() async throws {}

    /// Nothing to take: the launcher has no settings.
    func apply(_ settings: ModuleSettings) {}

    /// Finds the apps, shows them in the popup and watches the apps folders for changes.
    func start() async throws {
        status = .starting
        let list = LauncherList { [weak self] app in self?.open(app) }
        self.list = list
        loadCounts()
        system.popup.register(list, as: Self.module)
        findApps()
        let folders = AppFolder.standard(paths: system.paths).map(\.path)
        system.folders.start(folders) { [weak self] in self?.findApps() }
        status = .running
    }

    /// Takes the list out of the popup and stops watching.
    func stop() async {
        system.folders.stop()
        system.popup.unregister(Self.module)
        list = nil
        status = .off
    }

    /// Opens or closes the popup on the apps.
    func perform(_ action: KeyAction) {
        guard action == .module(Self.module) else { return }
        system.popup.toggle(Self.module)
    }

    /// Looks for the apps again, and shows the new list when the popup is open on it.
    private func findApps() {
        guard let list else { return }
        let found = AppIndex(files: system.files).apps(in: AppFolder.standard(paths: system.paths))
        guard found != list.apps else { return }
        list.apps = found
        log.report(.foundApps(found.count))
        system.popup.refresh(Self.module)
    }

    /// Reads the launch counts; without them the apps are only sorted by name.
    private func loadCounts() {
        do {
            list?.counts = try LaunchCounts(state: system.state).read()
        } catch {
            log.report(.warning(error))
        }
    }

    /// Counts `app`'s launch, and opens it through the module that opens apps, or by itself when
    /// none runs.
    private func open(_ app: LaunchableApp) {
        list?.counts[app.key, default: 0] += 1
        do {
            try LaunchCounts(state: system.state).record(app.key)
        } catch {
            log.report(.warning(error))
        }
        guard let bundleID = app.bundleID else {
            log.report(.noBundleID(app.name))
            return
        }
        guard !routes.openApp(bundleID) else { return }
        opening = Task { [system, log] in
            do {
                try await system.apps.open(bundleID)
            } catch {
                log.report(.failed(error))
            }
        }
    }
}
