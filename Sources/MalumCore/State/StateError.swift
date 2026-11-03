/// Why using the state folder failed.
public enum StateError: Error, Equatable, Sendable {
    /// The lock file at the path couldn't be opened or locked.
    case unlockable(path: String, reason: String)
    /// Reading or writing a file failed.
    case file(FileSystemError)
}

// MARK: - CustomStringConvertible

extension StateError: CustomStringConvertible {
    /// The problem as the user sees it.
    public var description: String {
        switch self {
        case .unlockable(let path, let reason):
            "couldn't lock \(path): \(reason)"
        case .file(let error):
            error.description
        }
    }
}
