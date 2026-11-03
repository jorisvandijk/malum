import Foundation

/// Locks on real files, through `flock`. The system lets go of them when the process ends,
/// even after a crash.
public struct LocalFileLocks: FileLocks {
    /// Lock files are readable and writable by the user only.
    private static let mode: mode_t = 0o600

    /// Creates access to real file locks.
    public init() {}

    /// Keeps the lock file open on purpose: closing it would let go of the lock.
    public func holdForLife(_ path: String) throws(StateError) -> Bool {
        let descriptor = try openLockFile(path)
        guard try takeWithoutWaiting(descriptor, path: path) else {
            close(descriptor)
            return false
        }
        return true
    }

    /// Takes the lock and lets go of it straight away.
    public func isHeld(_ path: String) throws(StateError) -> Bool {
        let descriptor = try openLockFile(path)
        defer { close(descriptor) }
        return try !takeWithoutWaiting(descriptor, path: path)
    }

    /// Closing the lock file at the end lets go of the lock.
    public func withLock<T>(_ path: String, _ body: () throws(StateError) -> T) throws(StateError) -> T {
        let descriptor = try openLockFile(path)
        defer { close(descriptor) }
        while flock(descriptor, LOCK_EX) != 0 {
            // A signal arriving while waiting isn't a failure: wait again.
            guard errno == EINTR else { throw .unlockable(path: path, reason: Self.lastError()) }
        }
        return try body()
    }

    /// Opens the lock file, creating it, and keeps it from leaking into commands Malum starts.
    private func openLockFile(_ path: String) throws(StateError) -> Int32 {
        let descriptor = open(path, O_CREAT | O_RDWR | O_CLOEXEC, Self.mode)
        guard descriptor >= 0 else { throw .unlockable(path: path, reason: Self.lastError()) }
        return descriptor
    }

    /// Tries to take the lock. Returns false when another process holds it.
    private func takeWithoutWaiting(_ descriptor: Int32, path: String) throws(StateError) -> Bool {
        guard flock(descriptor, LOCK_EX | LOCK_NB) != 0 else { return true }
        guard errno == EWOULDBLOCK else { throw .unlockable(path: path, reason: Self.lastError()) }
        return false
    }

    /// The text of the last system error.
    private static func lastError() -> String {
        String(cString: strerror(errno))
    }
}
