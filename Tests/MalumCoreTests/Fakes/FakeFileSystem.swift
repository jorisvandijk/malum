import Foundation
import Synchronization

@testable import MalumCore

/// A disk held in memory.
final class FakeFileSystem: FileSystem {
    /// What sits at each path.
    private let items: Mutex<[String: FileItem]>
    /// The text of each file.
    private let texts: Mutex<[String: String]>
    /// Files that can be run.
    private let executables: Mutex<Set<String>>
    /// Files and folders only the user can read.
    private let privates = Mutex<Set<String>>([])
    /// The bytes of files written as data.
    private let blobs = Mutex<[String: Data]>([:])
    /// Paths whose writes fail.
    let failing: Set<String>
    /// Paths spelled differently from how they are on disk, with their spelling on disk.
    let spellings: [String: String]

    init(
        items: [String: FileItem] = [:], texts: [String: String] = [:], failing: Set<String> = [],
        spellings: [String: String] = [:], executables: Set<String> = []
    ) {
        var all = items
        for path in texts.keys { all[path] = .file }
        self.items = Mutex(all)
        self.texts = Mutex(texts)
        self.executables = Mutex(executables)
        self.failing = failing
        self.spellings = spellings
    }

    func canonicalPath(_ path: String) -> String {
        spellings[path] ?? path
    }

    /// A path that only holds other paths is a folder.
    func item(at path: String) -> FileItem? {
        items.withLock { items in
            items[path] ?? (items.keys.contains { $0.hasPrefix(path + "/") } ? .directory : nil)
        }
    }

    /// Every path something sits at.
    var allPaths: Set<String> { items.withLock { Set($0.keys) } }

    func text(at path: String) -> String? {
        texts.withLock { $0[path] }
    }

    func read(_ path: String) throws(FileSystemError) -> String {
        guard let text = text(at: path) else { throw .unreadable(path: path, reason: "no such file") }
        return text
    }

    func data(at path: String) throws(FileSystemError) -> Data {
        if let blob = blobs.withLock({ $0[path] }) { return blob }
        return Data(try read(path).utf8)
    }

    /// Whether `path` was made readable only by the user.
    func isPrivate(_ path: String) -> Bool {
        privates.withLock { $0.contains(path) }
    }

    func createPrivateDirectory(_ path: String) throws(FileSystemError) {
        try createDirectory(path)
        privates.withLock { _ = $0.insert(path) }
    }

    func writePrivate(_ data: Data, to path: String) throws(FileSystemError) {
        try write(String(bytes: data, encoding: .utf8) ?? "", to: path)
        blobs.withLock { $0[path] = data }
        privates.withLock { _ = $0.insert(path) }
    }

    func write(_ text: String, to path: String) throws(FileSystemError) {
        guard !failing.contains(path) else { throw .unwritable(path: path, reason: "read-only") }
        items.withLock { $0[path] = .file }
        texts.withLock { $0[path] = text }
        blobs.withLock { $0[path] = nil }
    }

    func createDirectory(_ path: String) throws(FileSystemError) {
        guard !failing.contains(path) else { throw .noDirectory(path: path, reason: "read-only") }
        items.withLock { $0[path] = .directory }
    }

    func link(_ path: String, to destination: String) throws(FileSystemError) {
        guard !failing.contains(path) else { throw .unlinkable(path: path, reason: "read-only") }
        items.withLock { $0[path] = .link(to: destination) }
    }

    func copy(_ source: String, to destination: String) throws(FileSystemError) {
        guard !failing.contains(destination), holds(source), !holds(destination) else {
            throw .uncopyable(path: source, reason: "can't copy")
        }
        items.withLock { $0.merge(Self.moved($0, from: source, to: destination)) { $1 } }
        texts.withLock { $0.merge(Self.moved($0, from: source, to: destination)) { $1 } }
        executables.withLock { names in
            names.formUnion(names.filter { Self.isInside($0, source) }.map { destination + $0.dropFirst(source.count) })
        }
    }

    func exchange(_ path: String, _ other: String) throws(FileSystemError) {
        guard !failing.contains(other), holds(path), holds(other) else {
            throw .unswappable(path: path, other: other, reason: "can't swap")
        }
        items.withLock { $0 = Self.swapped($0, path, other) }
        texts.withLock { $0 = Self.swapped($0, path, other) }
        executables.withLock { names in
            let flags = Dictionary(uniqueKeysWithValues: names.map { ($0, true) })
            names = Set(Self.swapped(flags, path, other).keys)
        }
    }

    func remove(_ path: String) throws(FileSystemError) {
        guard !failing.contains(path) else { throw .unremovable(path: path, reason: "read-only") }
        items.withLock { $0 = $0.filter { !Self.isInside($0.key, path) } }
        texts.withLock { $0 = $0.filter { !Self.isInside($0.key, path) } }
        executables.withLock { $0 = $0.filter { !Self.isInside($0, path) } }
        blobs.withLock { $0 = $0.filter { !Self.isInside($0.key, path) } }
    }

    func contents(of path: String) throws(FileSystemError) -> [String] {
        guard item(at: path) == .directory else { throw .unlistable(path: path, reason: "not a folder") }
        let names = allPaths.filter { $0.hasPrefix(path + "/") }.map { $0.dropFirst(path.count + 1) }
        return Array(Set(names.compactMap { $0.split(separator: "/").first.map(String.init) }))
    }

    func isExecutable(_ path: String) -> Bool {
        executables.withLock { $0.contains(path) }
    }

    func makeExecutable(_ path: String) throws(FileSystemError) {
        guard !failing.contains(path), item(at: path) == .file else {
            throw .unwritable(path: path, reason: "read-only")
        }
        executables.withLock { _ = $0.insert(path) }
    }

    /// Whether something sits at `path` or inside it.
    private func holds(_ path: String) -> Bool {
        allPaths.contains { Self.isInside($0, path) }
    }

    /// Whether `path` is `folder` or inside it.
    private static func isInside(_ path: String, _ folder: String) -> Bool {
        path == folder || path.hasPrefix(folder + "/")
    }

    /// The entries at or inside `source`, as they'd be at `destination`.
    private static func moved<V>(_ entries: [String: V], from source: String, to destination: String) -> [String: V] {
        let inside = entries.filter { isInside($0.key, source) }
        return Dictionary(uniqueKeysWithValues: inside.map { (destination + $0.key.dropFirst(source.count), $0.value) })
    }

    /// The entries with what's at `path` and `other` swapped.
    private static func swapped<V>(_ entries: [String: V], _ path: String, _ other: String) -> [String: V] {
        let rest = entries.filter { !isInside($0.key, path) && !isInside($0.key, other) }
        return rest.merging(moved(entries, from: path, to: other)) { $1 }.merging(moved(entries, from: other, to: path))
        { $1 }
    }
}
