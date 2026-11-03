/// Malum's state folder, which the app and the command share.
///
/// Every write takes the folder's lock first, so the two never write at the same time. Writes
/// replace a file in one step, so reading needs no lock.
public struct StateFolder: Sendable {
    /// The file whose lock guards every write.
    private static let lockName = "state.lock"

    /// The disk.
    private let files: any FileSystem
    /// The locks.
    private let locks: any FileLocks
    /// Where the folder is.
    private let paths: Paths

    /// Creates access to the state folder.
    public init(files: any FileSystem, locks: any FileLocks, paths: Paths) {
        self.files = files
        self.locks = locks
        self.paths = paths
    }

    /// The path of the file called `name` in the folder.
    public func path(of name: String) -> String {
        "\(paths.stateDirectory)/\(name)"
    }

    /// Creates the folder when it's missing.
    public func prepare() throws(StateError) {
        do {
            try files.createDirectory(paths.stateDirectory)
        } catch {
            throw .file(error)
        }
    }

    /// Replaces the file called `name` with `text`, holding the folder's lock.
    public func write(_ text: String, to name: String) throws(StateError) {
        try prepare()
        try locks.withLock(path(of: Self.lockName)) { () throws(StateError) in try replace(name, with: text) }
    }

    /// Replaces the file called `name` with `text`, without the lock.
    private func replace(_ name: String, with text: String) throws(StateError) {
        do {
            try files.write(text, to: path(of: name))
        } catch {
            throw .file(error)
        }
    }

    /// The text of the file called `name`, or nil when there's no such file.
    public func read(_ name: String) throws(StateError) -> String? {
        guard files.item(at: path(of: name)) != nil else { return nil }
        do {
            return try files.read(path(of: name))
        } catch {
            throw .file(error)
        }
    }
}
