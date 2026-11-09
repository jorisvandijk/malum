/// Why the clipboard history couldn't be read or saved.
public enum ClipHistoryError: Error, Equatable {
    /// The index at `path` isn't a history Malum wrote.
    case unreadable(path: String)
    /// Reading or writing a file failed.
    case file(FileSystemError)
}
