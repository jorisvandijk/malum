/// Why a file operation failed.
public enum FileSystemError: Error, Equatable, Sendable {
    /// The file at the path couldn't be read.
    case unreadable(path: String, reason: String)
    /// The file at the path couldn't be written.
    case unwritable(path: String, reason: String)
    /// The folder at the path couldn't be created.
    case noDirectory(path: String, reason: String)
    /// The link at the path couldn't be made.
    case unlinkable(path: String, reason: String)
}

// MARK: - CustomStringConvertible

extension FileSystemError: CustomStringConvertible {
    /// The problem as the user sees it.
    public var description: String {
        switch self {
        case .unreadable(let path, let reason):
            "couldn't read \(path): \(reason)"
        case .unwritable(let path, let reason):
            "couldn't write \(path): \(reason)"
        case .noDirectory(let path, let reason):
            "couldn't create \(path): \(reason)"
        case .unlinkable(let path, let reason):
            "couldn't link \(path): \(reason)"
        }
    }
}
