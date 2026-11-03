import MalumCore
import MalumPlatform

/// The app's config: loads `malum.toml`, and loads it again when it's saved or `malum reload` asks.
@MainActor
final class LiveConfig {
    /// Reads and checks the file.
    private let reloader: ConfigReloader
    /// Watches the file, once dots is known.
    private var watcher: ConfigWatcher?

    /// Creates the config with nothing loaded yet.
    init(reloader: ConfigReloader) {
        self.reloader = reloader
    }

    /// Loads `malum.toml` and reports what it found. Unless `force` is set, a file that reads the
    /// same as last time is skipped.
    func reload(force: Bool) {
        guard let report = reloader.reload(force: force) else { return }
        report.messages.forEach(terminal.report)
        // TODO: apply the changed settings to the modules, once there are any.
        follow(reloader.path)
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
