import MalumCore
import MalumPlatform

/// The app's config: loads `malum.toml`, and loads it again when it's saved or `malum reload` asks.
/// Each load switches the modules on and off and hands them their new settings.
@MainActor
final class LiveConfig {
    /// Reads and checks the file.
    private let reloader: ConfigReloader
    /// Starts and stops the modules.
    private let modules: ModuleSwitch
    /// Watches the file, once dots is known.
    private var watcher: ConfigWatcher?

    /// Creates the config with nothing loaded yet and every module off.
    init(reloader: ConfigReloader, modules: ModuleSwitch) {
        self.reloader = reloader
        self.modules = modules
    }

    /// Loads `malum.toml` and reports what it found. Unless `force` is set, a file that reads the
    /// same as last time is skipped.
    func reload(force: Bool) {
        guard let report = reloader.reload(force: force) else { return }
        report.messages.forEach(terminal.report)
        follow(reloader.path)
        let enabled = reloader.enabled
        let settings = reloader.settings
        Task { [weak self] in
            guard let self else { return }
            let messages = await self.modules.update(enabled: enabled, settings: settings, changed: report.changed)
            messages.forEach(terminal.report)
        }
    }

    /// Watches `path`, the file the last load looked for, when that isn't watched already.
    private func follow(_ path: String?) {
        guard watcher?.path != path else { return }
        watcher?.stop()
        watcher = path.map { path in ConfigWatcher(path: path) { [weak self] in self?.reload(force: false) } }
        guard let watcher, !watcher.isWatching else { return }
        terminal.report(
            Message(.warn, "couldn't watch \(watcher.folder), run \(Project.command) reload after a change"))
    }
}
