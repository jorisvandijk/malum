import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ClipHistoryTests {
    private let folder = "/Users/test/state/history"
    private var index: String { "\(folder)/index.json" }
    private let files = FakeFileSystem()

    private func history(limit: Int = 3) -> ClipHistory {
        var tick = 0.0
        return ClipHistory(files: files, folder: folder, limit: limit) {
            tick += 1
            return Date(timeIntervalSince1970: tick)
        }
    }

    private func texts(_ history: ClipHistory) -> [String] {
        history.entries.map { $0.text ?? $0.paths?.joined() ?? "image" }
    }

    @Test func copiesAreAddedNewestFirst() throws {
        let history = history()
        try history.add(.text("one", rtf: nil))
        try history.add(.files(["/a", "/b"]))
        #expect(texts(history) == ["/a/b", "one"])
    }

    @Test func sameCopyMovesToTheTopAndKeepsItsRichText() throws {
        let history = history()
        try history.add(.text("one", rtf: Data("{\\rtf1}".utf8)))
        let id = history.entries.first?.id
        try history.add(.text("two", rtf: nil))
        try history.add(.text("one", rtf: nil))
        #expect(texts(history) == ["one", "two"])
        #expect(history.entries.first?.id == id)
        #expect(history.entries.first?.rtf == Data("{\\rtf1}".utf8))
    }

    @Test func emptyTextIsntKept() throws {
        let history = history()
        #expect(try !history.add(.text(" \n", rtf: nil)))
        #expect(history.entries.isEmpty)
    }

    @Test func oldestPastTheLimitAreDropped() throws {
        let history = history(limit: 2)
        for text in ["a", "b", "c"] { try history.add(.text(text, rtf: nil)) }
        #expect(texts(history) == ["c", "b"])
    }

    @Test func imagesAreStoredPrivatelyAndTheSameImageMovesUp() throws {
        let history = history()
        let png = Data([0x89, 0x50, 0x4E, 0x47])
        try history.add(.image(png: png))
        try history.add(.text("x", rtf: nil))
        try history.add(.image(png: png))
        #expect(texts(history) == ["image", "x"])
        guard let image = history.entries.first else { return }
        #expect(try files.data(at: history.imagePath(of: image)) == png)
        #expect(files.isPrivate(history.imagePath(of: image)))
        #expect(files.isPrivate(index))
        #expect(files.isPrivate(folder))
    }

    @Test func imagesOver20MBArentKept() throws {
        let history = history()
        #expect(try !history.add(.image(png: Data(count: ClipHistory.maxImageBytes + 1))))
    }

    @Test func deleteRemovesTheEntryAndItsImage() throws {
        let history = history()
        try history.add(.image(png: Data([1, 2, 3])))
        guard let image = history.entries.first else { return }
        try history.delete(image.id)
        #expect(history.entries.isEmpty)
        #expect(files.item(at: history.imagePath(of: image)) == nil)
    }

    @Test func clearEmptiesTheHistory() throws {
        let history = history()
        try history.add(.text("a", rtf: nil))
        try history.add(.image(png: Data([1])))
        try history.clear()
        #expect(history.entries.isEmpty)
        #expect(try ClipHistory(files: files, folder: folder, limit: 3).loaded().entries.isEmpty)
    }

    @Test func moveToTopMakesAnEntryTheNewest() throws {
        let history = history()
        try history.add(.text("a", rtf: nil))
        try history.add(.text("b", rtf: nil))
        guard let older = history.entries.last else { return }
        try history.moveToTop(older.id)
        #expect(texts(history) == ["a", "b"])
    }

    @Test func historyIsReadBackAndMissingImagesDropped() throws {
        let history = history()
        try history.add(.text("kept", rtf: nil))
        try history.add(.image(png: Data([7])))
        guard let image = history.entries.first else { return }
        try files.remove(history.imagePath(of: image))
        let again = try ClipHistory(files: files, folder: folder, limit: 3).loaded()
        #expect(texts(again) == ["kept"])
    }

    @Test func damagedIndexIsReported() throws {
        try files.write("nope", to: index)
        #expect(throws: ClipHistoryError.unreadable(path: index)) {
            try ClipHistory(files: files, folder: folder, limit: 3).load()
        }
    }

    @Test func fingerprintStaysTheSameAndTellsBytesApart() {
        #expect(Fingerprint.of(Data([1, 2])) == Fingerprint.of(Data([1, 2])))
        #expect(Fingerprint.of(Data([1, 2])) != Fingerprint.of(Data([2, 1])))
    }
}

extension ClipHistory {
    /// The history after `load`.
    fileprivate func loaded() throws -> ClipHistory {
        try load()
        return self
    }
}
