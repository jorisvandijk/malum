import MalumCore
import MalumPlatform

/// The app's config: loads `malum.toml` and the modules' own files, and loads them again when one is
/// saved or `malum reload` asks.
/// Each load switches the modules on and off and hands them their new settings.
@MainActor
final class LiveConfig {
    /// How long to wait between checks for permissions granted or taken away in System Settings, and
    /// for what else macOS doesn't announce.
    private static let recheckSeconds = 2

    /// Reads and checks the file.
    private let reloader: ConfigReloader
    /// Starts and stops the modules.
    private let modules: ModuleSwitch
    /// Where safe mode and the disabled modules are saved.
    private let store: OverrideStore
    /// Safe mode and the disabled modules, as the last load found them.
    private(set) var overrides = Overrides()
    /// Watches the files, once dots is known.
    private var watcher: ConfigWatcher?
    /// What the last load found, or nil before the first one.
    private(set) var report: ConfigReport?
    /// Whether modules may run, which they may only once Malum is signed with its own certificate.
    private var modulesAllowed = false
    /// Whether Malum is quitting, which keeps the modules off for good.
    private var quitting = false
    /// Checks the modules again and again, while any module runs or waits.
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
        guard !quitting else { return }
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
        follow(reloader.path, with: reloader.watchedFiles)
        onUpdate()
        let switchedOn = overrides.allowed(reloader.enabled)
        let settings = reloader.moduleSettings
        Task { [weak self] in
            guard let self else { return }
            // Read when the update is queued, so an update can't start modules after quitting stopped them.
            let enabled = self.modulesAllowed ? switchedOn : []
            let messages = await self.modules.update(enabled: enabled, settings: settings, changed: report.changed)
            messages.forEach(announce)
            self.onUpdate()
            self.watchModules()
        }
    }

    /// Has the running modules set up again what macOS may have dropped.
    func resume() {
        Task { [weak self] in
            guard let self else { return }
            await self.modules.resume().forEach(announce)
        }
    }

    /// Stops every module and keeps them off from now on, for quitting.
    func stopModules() async {
        quitting = true
        modulesAllowed = false
        recheck?.cancel()
        let messages = await modules.update(enabled: [], settings: reloader.moduleSettings, changed: [])
        messages.forEach(announce)
    }

    /// The switched-on modules that wait for permissions, with the ones they're missing.
    var waiting: [String: Set<Permission>] { modules.waiting }

    /// Whether a module runs or waits, so the modules need checking.
    private var hasModulesToCheck: Bool { !modules.started.isEmpty || !modules.waiting.isEmpty }

    /// Starts checking the modules while one runs or waits, unless that runs already.
    private func watchModules() {
        guard hasModulesToCheck, recheck == nil else { return }
        recheck = Task { [weak self] in
            while await self?.recheckModules() == true {}
        }
    }

    /// Waits a moment, has the modules check their permissions and what else macOS doesn't announce,
    /// and says whether to keep checking.
    private func recheckModules() async -> Bool {
        do {
            try await Task.sleep(for: .seconds(Self.recheckSeconds))
        } catch {
            recheck = nil
            return false
        }
        let messages = await modules.recheck()
        messages.forEach(announce)
        if !messages.isEmpty {
            onUpdate()
        }
        guard hasModulesToCheck else {
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

    /// Watches `files` in the folder of `path`, the `malum.toml` the last load looked for, when they
    /// aren't watched already.
    private func follow(_ path: String?, with files: [String]) {
        guard watcher?.paths != files else { return }
        watcher?.stop()
        watcher = path.map { path in
            ConfigWatcher(folder: Paths.folder(of: path), paths: files) { [weak self] in self?.reload(force: false) }
        }
        guard let watcher, !watcher.isWatching else { return }
        announce(.unwatchable(watcher.folder))
    }
}
