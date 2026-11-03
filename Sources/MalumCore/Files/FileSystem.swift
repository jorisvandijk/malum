/// The files Malum reads and writes, behind a protocol so tests never touch the disk.
public protocol FileSystem: Sendable {
    /// What sits at `path`, or nil when nothing does. A link is reported as a link, not followed.
    func item(at path: String) -> FileItem?
    /// The path as it's spelled on disk, with links resolved, so `~/git` and `~/Git` on a
    /// case-insensitive disk give the same answer. A path that doesn't exist comes back unchanged.
    func canonicalPath(_ path: String) -> String
    /// The text of the file at `path`.
    func read(_ path: String) throws(FileSystemError) -> String
    /// Replaces the file at `path` with `text` in one step.
    func write(_ text: String, to path: String) throws(FileSystemError)
    /// Creates the folder at `path` and any missing folders above it.
    func createDirectory(_ path: String) throws(FileSystemError)
    /// Makes `path` a symbolic link to `destination`, replacing a link that's already there.
    func link(_ path: String, to destination: String) throws(FileSystemError)
}
