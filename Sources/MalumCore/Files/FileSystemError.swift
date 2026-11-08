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
    /// The file at the path is a TOML file, which only the user writes.
    case userFile(path: String)
    /// A file was to be written at the path, but a folder is there.
    case isFolder(path: String)
    /// What's at the two paths can't be swapped on this system.
    case swapUnsupported(path: String, other: String)
}
