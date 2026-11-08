import Foundation

/// The real disk, through `FileManager`.
public struct LocalFileSystem: FileSystem {
    /// Creates access to the real disk.
    public init() {}

    /// What sits at `path`, without following a link.
    public func item(at path: String) -> FileItem? {
        let manager = FileManager.default
        if let destination = try? manager.destinationOfSymbolicLink(atPath: path) {  // Fails when it isn't a link.
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
        try refuseTOML(path)
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
        try refuseTOML(path)
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

    /// Copies with `FileManager`, which keeps the files' attributes.
    public func copy(_ source: String, to destination: String) throws(FileSystemError) {
        try refuseTOML(destination)
        do {
            try FileManager.default.copyItem(atPath: source, toPath: destination)
        } catch {
            throw .uncopyable(path: source, reason: error.localizedDescription)
        }
    }

    /// Swaps the two with `renamex_np`, so neither path is ever empty. Linux has no such call
    /// that Swift can reach, and Malum never swaps there.
    public func exchange(_ path: String, _ other: String) throws(FileSystemError) {
        try refuseTOML(path)
        try refuseTOML(other)
        #if canImport(Darwin)
            guard renamex_np(path, other, UInt32(RENAME_SWAP)) != 0 else { return }
            throw .unswappable(path: path, other: other, reason: String(cString: strerror(errno)))
        #else
            throw .unswappable(path: path, other: other, reason: "not supported on this system")
        #endif
    }

    /// Removes with `FileManager`.
    public func remove(_ path: String) throws(FileSystemError) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            throw .unremovable(path: path, reason: error.localizedDescription)
        }
    }

    /// Lists with `FileManager`.
    public func contents(of path: String) throws(FileSystemError) -> [String] {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: path)
        } catch {
            throw .unlistable(path: path, reason: error.localizedDescription)
        }
    }

    /// Asks `FileManager`.
    public func isExecutable(_ path: String) -> Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }

    /// Sets the permissions to `rwxr-xr-x`.
    public func makeExecutable(_ path: String) throws(FileSystemError) {
        do {
            try FileManager.default.setAttributes([.posixPermissions: Self.executableMode], ofItemAtPath: path)
        } catch {
            throw .unwritable(path: path, reason: error.localizedDescription)
        }
    }

    /// Never lets anything land on a TOML file, since those are the user's.
    private func refuseTOML(_ path: String) throws(FileSystemError) {
        guard (path as NSString).pathExtension.lowercased() != Paths.tomlExtension else {
            throw .userFile(path: path)
        }
    }

    /// `rwxr-xr-x`.
    private static let executableMode = 0o755
}
