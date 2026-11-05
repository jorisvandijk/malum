/// Why using the state folder failed.
public enum StateError: Error, Equatable, Sendable {
    /// The lock file at the path couldn't be opened or locked.
    case unlockable(path: String, reason: String)
    /// Reading or writing a file failed.
    case file(FileSystemError)
}
