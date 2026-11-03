import Foundation

/// The real disk, through `FileManager`.
public struct LocalFileSystem: FileSystem {
    /// Creates access to the real disk.
    public init() {}

    /// What sits at `path`, without following a link.
    public func item(at path: String) -> FileItem? {
        let manager = FileManager.default
        // Failing here is the expected answer when the path isn't a link.
        if let destination = try? manager.destinationOfSymbolicLink(atPath: path) {
            return .link(to: destination)
        }
        var isDirectory: ObjCBool = false
        guard manager.fileExists(atPath: path, isDirectory: &isDirectory) else { return nil }
        return isDirectory.boolValue ? .directory : .file
    }

    /// Asks `realpath`, which on macOS also returns each name in the case it has on disk.
    public func canonicalPath(_ path: String) -> String {
        guard let resolved = realpath(path, nil) else { return path }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    /// The text of the file at `path`.
    public func read(_ path: String) throws(FileSystemError) -> String {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw .unreadable(path: path, reason: error.localizedDescription)
        }
    }

    /// Writes to a temporary file first, then moves it over `path`.
    public func write(_ text: String, to path: String) throws(FileSystemError) {
        do {
            try Data(text.utf8).write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            throw .unwritable(path: path, reason: error.localizedDescription)
        }
    }

    /// Creates the folder at `path` and any missing folders above it.
    public func createDirectory(_ path: String) throws(FileSystemError) {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        } catch {
            throw .noDirectory(path: path, reason: error.localizedDescription)
        }
    }

    /// Removes a link already at `path`, then links it to `destination`.
    public func link(_ path: String, to destination: String) throws(FileSystemError) {
        let manager = FileManager.default
        do {
            if case .link = item(at: path) {
                try manager.removeItem(atPath: path)
            }
            try manager.createSymbolicLink(atPath: path, withDestinationPath: destination)
        } catch {
            throw .unlinkable(path: path, reason: error.localizedDescription)
        }
    }
}
