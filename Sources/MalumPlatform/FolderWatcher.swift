import MalumCore

/// Watches folders for apps being added or removed, with one `ConfigWatcher` on each folder.
@MainActor
public final class FolderWatcher: FolderWatch {
    /// The watch on each folder.
    private var watchers: [ConfigWatcher] = []

    /// Creates a watcher that watches nothing yet.
    public init() {}

    /// Starts watching `folders`; a missing folder isn't watched.
    public func start(_ folders: [String], onChange: @escaping @MainActor () -> Void) {
        stop()
        watchers = folders.map { ConfigWatcher(folder: $0, paths: [], onChange: onChange) }.filter(\.isWatching)
    }

    /// Stops watching.
    public func stop() {
        for watcher in watchers { watcher.stop() }
        watchers = []
    }
}
