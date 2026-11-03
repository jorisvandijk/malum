/// What sits at a path on disk.
public enum FileItem: Equatable, Sendable {
    /// A regular file.
    case file
    /// A folder.
    case directory
    /// A symbolic link, with the path it points to.
    case link(to: String)
}
