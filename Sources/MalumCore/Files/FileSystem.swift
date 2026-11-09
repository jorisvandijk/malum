import Foundation

/// The files Malum reads and writes, behind a protocol so tests never touch the disk.
public protocol FileSystem: Sendable {
    /// What sits at `path`, or nil when nothing does. A link is reported as a link, not followed.
    func item(at path: String) -> FileItem?
    /// The path as it's spelled on disk, with links resolved, so `~/git` and `~/Git` on a
    /// case-insensitive disk give the same answer. A path that doesn't exist comes back unchanged.
    func canonicalPath(_ path: String) -> String
    /// The text of the file at `path`.
    func read(_ path: String) throws(FileSystemError) -> String
    /// The bytes of the file at `path`, for a file that may not be text, such as a binary property list.
    func data(at path: String) throws(FileSystemError) -> Data
    /// Replaces the file at `path` with `text` in one step.
    func write(_ text: String, to path: String) throws(FileSystemError)
    /// Creates the folder at `path` and any missing folders above it.
    func createDirectory(_ path: String) throws(FileSystemError)
    /// Creates the folder at `path`, and any missing above it, that only the user can open.
    func createPrivateDirectory(_ path: String) throws(FileSystemError)
    /// Replaces the file at `path` with `data` in one step, readable only by the user.
    func writePrivate(_ data: Data, to path: String) throws(FileSystemError)
    /// Makes `path` a symbolic link to `destination`, replacing a link that's already there.
    func link(_ path: String, to destination: String) throws(FileSystemError)
    /// Copies the file or folder at `source` to `destination`, which must not exist yet.
    func copy(_ source: String, to destination: String) throws(FileSystemError)
    /// Swaps what's at `path` with what's at `other` in one step. Both must exist.
    func exchange(_ path: String, _ other: String) throws(FileSystemError)
    /// Removes the file or folder at `path`, with everything in it.
    func remove(_ path: String) throws(FileSystemError)
    /// The names of what's in the folder at `path`.
    func contents(of path: String) throws(FileSystemError) -> [String]
    /// Whether the file at `path` can be run.
    func isExecutable(_ path: String) -> Bool
    /// Lets the file at `path` be run.
    func makeExecutable(_ path: String) throws(FileSystemError)
}

extension FileSystem {
    /// The text at `path` when a regular file is there, or nil for a folder, a link or nothing.
    func text(ifFileAt path: String) throws(FileSystemError) -> String? {
        guard item(at: path) == .file else { return nil }
        return try read(path)
    }

    /// Puts `staged` at `destination` in one step, then removes what was there, which the swap
    /// left at `staged`. Both must exist.
    func replace(_ destination: String, with staged: String) throws(FileSystemError) {
        try exchange(staged, destination)
        try? remove(staged)  // The new one is in place; the next replace removes a leftover.
    }
}
