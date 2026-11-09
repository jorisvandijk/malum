import Foundation

/// The clipboard history, newest first, kept in `history/` in the state folder: `index.json` with
/// the entries and one PNG for each image, all readable only by the user.
@MainActor
public final class ClipHistory {
    /// The largest image kept, in bytes.
    static let maxImageBytes = 20_000_000
    /// The file with the entries.
    private static let indexName = "index.json"

    /// The disk.
    private let files: any FileSystem
    /// The history folder.
    let folder: String
    /// The time now, which tests set.
    private let now: () -> Date
    /// The entries, newest first.
    public private(set) var entries: [ClipEntry] = []
    /// How many entries are kept.
    public var limit: Int

    /// Creates an empty history in `folder` that keeps `limit` entries.
    public init(files: any FileSystem, folder: String, limit: Int, now: @escaping () -> Date = Date.init) {
        self.files = files
        self.folder = folder
        self.limit = limit
        self.now = now
    }

    /// Reads the history from disk. An image whose file is gone is dropped, since it can't be pasted.
    public func load() throws(ClipHistoryError) {
        let index = "\(folder)/\(Self.indexName)"
        guard files.item(at: index) != nil else { return }
        do {
            entries = try Self.decoder.decode([ClipEntry].self, from: try files.data(at: index))
        } catch {
            throw .unreadable(path: index)
        }
        entries.removeAll { $0.kind == .image && files.item(at: imagePath(of: $0)) == nil }
        try trimAndSave(saving: false)
    }

    /// Adds `copy` at the top; the same copy already listed moves to the top instead. Says whether
    /// it was kept: empty text and images over 20 MB aren't.
    @discardableResult
    public func add(_ copy: Copy) throws(ClipHistoryError) -> Bool {
        guard var entry = entry(for: copy) else { return false }
        if let existing = entries.first(where: { $0.key == entry.key }) {
            entries.removeAll { $0.id == existing.id }
            entry = ClipEntry(
                id: existing.id, kind: existing.kind, date: entry.date, text: entry.text,
                rtf: entry.rtf ?? existing.rtf, paths: entry.paths, imageHash: entry.imageHash)
        } else {
            try writeImage(of: copy, for: entry)
        }
        entries.insert(entry, at: 0)
        try trimAndSave(saving: true)
        return true
    }

    /// Makes the entry with `id` the newest, after it was picked.
    public func moveToTop(_ id: String) throws(ClipHistoryError) {
        guard let place = entries.firstIndex(where: { $0.id == id }) else { return }
        var moved = entries.remove(at: place)
        moved.date = now()
        entries.insert(moved, at: 0)
        try trimAndSave(saving: true)
    }

    /// Deletes the entry with `id`, and its image.
    public func delete(_ id: String) throws(ClipHistoryError) {
        guard let place = entries.firstIndex(where: { $0.id == id }) else { return }
        removeImage(of: entries.remove(at: place))
        try trimAndSave(saving: true)
    }

    /// Deletes every entry and image.
    public func clear() throws(ClipHistoryError) {
        entries.forEach(removeImage)
        entries = []
        try trimAndSave(saving: true)
    }

    /// Where an image entry's PNG is.
    public func imagePath(of entry: ClipEntry) -> String {
        "\(folder)/\(entry.imageName)"
    }

    /// The entry for `copy`, nil when it isn't kept.
    private func entry(for copy: Copy) -> ClipEntry? {
        let id = UUID().uuidString
        switch copy {
        case .text(let text, let rtf):
            guard !text.allSatisfy(\.isWhitespace) else { return nil }
            return ClipEntry(id: id, kind: .text, date: now(), text: text, rtf: rtf)
        case .image(let png):
            guard !png.isEmpty, png.count <= Self.maxImageBytes else { return nil }
            return ClipEntry(id: id, kind: .image, date: now(), imageHash: Fingerprint.of(png))
        case .files(let paths):
            guard !paths.isEmpty else { return nil }
            return ClipEntry(id: id, kind: .files, date: now(), paths: paths)
        }
    }

    /// Drops the oldest entries past the limit, then writes the index when `saving` or anything
    /// was dropped.
    private func trimAndSave(saving: Bool) throws(ClipHistoryError) {
        let dropped = entries.dropFirst(max(limit, 0))
        dropped.forEach(removeImage)
        entries.removeLast(dropped.count)
        guard saving || !dropped.isEmpty else { return }
        let index: Data
        do {
            index = try Self.encoder.encode(entries)
        } catch {
            throw .unreadable(path: "\(folder)/\(Self.indexName)")
        }
        try write(index, to: "\(folder)/\(Self.indexName)")
    }

    /// Writes the PNG of an image `copy` for its new `entry`.
    private func writeImage(of copy: Copy, for entry: ClipEntry) throws(ClipHistoryError) {
        guard case .image(let png) = copy else { return }
        try write(png, to: imagePath(of: entry))
    }

    /// Writes `data` to `path` in the history folder, readable only by the user.
    private func write(_ data: Data, to path: String) throws(ClipHistoryError) {
        do {
            try files.createPrivateDirectory(folder)
            try files.writePrivate(data, to: path)
        } catch {
            throw .file(error)
        }
    }

    /// Removes an image entry's PNG; one that's already gone needs nothing.
    private func removeImage(of entry: ClipEntry) {
        guard entry.kind == .image, files.item(at: imagePath(of: entry)) != nil else { return }
        try? files.remove(imagePath(of: entry))  // A leftover image is harmless, and never listed.
    }

    /// Reads the index, with dates as ISO 8601.
    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Writes the index, with dates as ISO 8601.
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
