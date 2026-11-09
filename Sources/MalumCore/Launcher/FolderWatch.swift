/// Watches folders for apps being added or removed. `FolderWatcher` in MalumPlatform is the real
/// one.
@MainActor
public protocol FolderWatch: AnyObject {
    /// Starts watching `folders`, calling `onChange` once each burst of changes has settled.
    func start(_ folders: [String], onChange: @escaping @MainActor () -> Void)
    /// Stops watching.
    func stop()
}
