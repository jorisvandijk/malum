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
    /// The file or folder at the path couldn't be copied.
    case uncopyable(path: String, reason: String)
    /// What's at the two paths couldn't be swapped.
    case unswappable(path: String, other: String, reason: String)
    /// The file or folder at the path couldn't be removed.
    case unremovable(path: String, reason: String)
    /// The folder at the path couldn't be listed.
    case unlistable(path: String, reason: String)
}

// MARK: - ReportableError

extension FileSystemError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unreadable(let path, let reason):
            "couldn't read \(private: path): \(reason)"
        case .unwritable(let path, let reason):
            "couldn't write \(private: path): \(reason)"
        case .noDirectory(let path, let reason):
            "couldn't create \(private: path): \(reason)"
        case .unlinkable(let path, let reason):
            "couldn't link \(private: path): \(reason)"
        case .uncopyable(let path, let reason):
            "couldn't copy \(private: path): \(reason)"
        case .unswappable(let path, let other, let reason):
            "couldn't swap \(private: path) with \(private: other): \(reason)"
        case .unremovable(let path, let reason):
            "couldn't remove \(private: path): \(reason)"
        case .unlistable(let path, let reason):
            "couldn't list \(private: path): \(reason)"
        }
    }
}
