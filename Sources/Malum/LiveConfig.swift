import MalumCore
import MalumPlatform

/// The app's config: loads `malum.toml`, and loads it again when it's saved or `malum reload` asks.
/// Each load switches the modules on and off and hands them their new settings.
@MainActor
final class LiveConfig {
    /// How long to wait between checks for permissions granted in System Settings, which doesn't say when.
    private static let recheckSeconds = 2

    /// Reads and checks the file.
    private let reloader: ConfigReloader
    /// Starts and stops the modules.
    private let modules: ModuleSwitch
    /// Where safe mode and the disabled modules are saved.
    private let store: OverrideStore
    /// Safe mode and the disabled modules, as the last load found them.
    private(set) var overrides = Overrides()
    /// Watches the file, once dots is known.
    private var watcher: ConfigWatcher?
    /// What the last load found, or nil before the first one.
    private(set) var report: ConfigReport?
    /// Whether modules may run, which they may only once Malum is signed with its own certificate.
    private var modulesAllowed = false
    /// Checks again and again for the permissions waiting modules need, while any module waits.
    private var recheck: Task<Void, Never>?
    /// Runs after each load, and again once the modules have been switched.
    var onUpdate: @MainActor () -> Void = {}

    /// Creates the config with nothing loaded yet and every module off.
    init(reloader: ConfigReloader, modules: ModuleSwitch, overrides: OverrideStore) {
        self.reloader = reloader
        self.modules = modules
        store = overrides
    }

    /// Has the modules undo what an earlier run left behind, then loads `malum.toml` for the first time.
    func start() {
        Task { [weak self] in
            guard let self else { return }
            await self.modules.cleanUp().forEach(announce)
            self.reload(force: true)
        }
    }

    /// Lets the modules run from now on. Before the first load, that load switches them on; after it,
    /// loading again does, since the modules have cleaned up by then.
    func allowModules() {
        modulesAllowed = true
        guard report != nil else { return }
        reload(force: true)
    }

    /// Changes the saved overrides with `edit`, then loads again so the modules follow.
    func change(_ edit: (OverrideStore) throws(StateError) -> Void) {
        do {
            try edit(store)
        } catch {
            announce(.failed(error))
            return
        }
        reload(force: true)
    }

    /// Loads `malum.toml` and reports what it found. Unless `force` is set, a file that reads the
    /// same as last time is skipped.
    func reload(force: Bool) {
        guard let report = reloader.reload(force: force) else { return }
        self.report = report
        report.messages.forEach(announce)
        readOverrides()
        follow(reloader.path)
        onUpdate()
        let enabled = modulesAllowed ? overrides.allowed(reloader.enabled) : []
        let settings = reloader.settings
        Task { [weak self] in
            guard let self else { return }
            let messages = await self.modules.update(enabled: enabled, settings: settings, changed: report.changed)
            messages.forEach(announce)
            self.onUpdate()
            self.watchPermissions()
        }
    }

    /// The switched-on modules that wait for permissions, with the ones they're missing.
    var waiting: [String: Set<Permission>] { modules.waiting }

    /// Starts checking for granted permissions while a module waits for them, unless that runs already.
    private func watchPermissions() {
        guard !modules.waiting.isEmpty, recheck == nil else { return }
        recheck = Task { [weak self] in
            while await self?.recheckPermissions() == true {}
        }
    }

    /// Waits a moment, starts the modules whose permissions were granted, and says whether to keep checking.
    private func recheckPermissions() async -> Bool {
        do {
            try await Task.sleep(for: .seconds(Self.recheckSeconds))
        } catch {
            recheck = nil
            return false
        }
        let messages = await modules.retryWaiting()
        messages.forEach(announce)
        if !messages.isEmpty {
            onUpdate()
        }
        guard !modules.waiting.isEmpty else {
            recheck = nil
            return false
        }
        return true
    }

    /// Reads the saved overrides. When they can't be read, the last ones stay.
    private func readOverrides() {
        do {
            overrides = try store.read()
        } catch {
            announce(.failed(error))
        }
    }

    /// Where `malum.toml` was looked for last, or nil when dots isn't known.
    var path: String? { reloader.path }

    /// Watches `path`, the file the last load looked for, when that isn't watched already.
    private func follow(_ path: String?) {
        guard watcher?.path != path else { return }
        watcher?.stop()
        watcher = path.map { path in ConfigWatcher(path: path) { [weak self] in self?.reload(force: false) } }
        guard let watcher, !watcher.isWatching else { return }
        announce(.unwatchable(watcher.folder))
    }
}
