/// Advisory locks on files, which the app and the command use to stay out of each other's way.
///
/// A lock file is created when it's missing. Its contents are never used.
public protocol FileLocks: Sendable {
    /// Takes the lock on `path` for as long as this process runs, unless another process holds it.
    /// Returns whether this process now holds it.
    func holdForLife(_ path: String) throws(StateError) -> Bool
    /// Whether another process holds the lock on `path` right now.
    func isHeld(_ path: String) throws(StateError) -> Bool
    /// Runs `body` while holding the lock on `path`, waiting for another process to let go of it first.
    func withLock<T>(_ path: String, _ body: () throws(StateError) -> T) throws(StateError) -> T
}
