import Synchronization

@testable import MalumCore

/// A disk held in memory.
final class FakeFileSystem: FileSystem {
    /// What sits at each path.
    private let items: Mutex<[String: FileItem]>
    /// The text of each file.
    private let texts: Mutex<[String: String]>
    /// Paths whose writes fail.
    let failing: Set<String>
    /// Paths spelled differently from how they are on disk, with their spelling on disk.
    let spellings: [String: String]

    init(
        items: [String: FileItem] = [:], texts: [String: String] = [:], failing: Set<String> = [],
        spellings: [String: String] = [:]
    ) {
        var all = items
        for path in texts.keys { all[path] = .file }
        self.items = Mutex(all)
        self.texts = Mutex(texts)
        self.failing = failing
        self.spellings = spellings
    }

    func canonicalPath(_ path: String) -> String {
        spellings[path] ?? path
    }

    func item(at path: String) -> FileItem? {
        items.withLock { $0[path] }
    }

    func text(at path: String) -> String? {
        texts.withLock { $0[path] }
    }

    func read(_ path: String) throws(FileSystemError) -> String {
        guard let text = text(at: path) else { throw .unreadable(path: path, reason: "no such file") }
        return text
    }

    func write(_ text: String, to path: String) throws(FileSystemError) {
        guard !failing.contains(path) else { throw .unwritable(path: path, reason: "read-only") }
        items.withLock { $0[path] = .file }
        texts.withLock { $0[path] = text }
    }

    func createDirectory(_ path: String) throws(FileSystemError) {
        guard !failing.contains(path) else { throw .noDirectory(path: path, reason: "read-only") }
        items.withLock { $0[path] = .directory }
    }

    func link(_ path: String, to destination: String) throws(FileSystemError) {
        guard !failing.contains(path) else { throw .unlinkable(path: path, reason: "read-only") }
        items.withLock { $0[path] = .link(to: destination) }
    }
}
