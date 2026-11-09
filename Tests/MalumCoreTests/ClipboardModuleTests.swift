import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ClipboardModuleTests {
    private let paths = Paths(home: "/Users/test")
    private let files = FakeFileSystem()
    private let clipboard = FakeClipboard()
    private let popup = FakePopup()
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func started(_ settings: ModuleSettings = [:]) async throws -> ClipboardModule {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        let system = ClipboardSystem(files: files, state: state, clipboard: clipboard, popup: PopupCenter(popup: popup))
        let module = ClipboardModule(system: system, log: Log(writer: RecordingLogWriter())) { [start] in start }
        module.apply(settings)
        try await module.start()
        return module
    }

    private var titles: [String] {
        popup.shown.last?.rows.map(\.title) ?? []
    }

    @Test func offersTheClipboardAction() async throws {
        #expect(try await started().hotkeys == HotkeyOffer(actions: ["clipboard"]))
    }

    @Test func copiesShowNewestFirstWithTheirAge() async throws {
        let module = try await started()
        clipboard.copy(.copied(.text("first\nsecond line", rtf: nil)))
        clipboard.copy(.copied(.files(["/Users/test/a.pdf", "/Users/test/b.txt"])))
        module.perform(.module("clipboard"))
        #expect(titles == ["a.pdf, b.txt", "first …"])
        #expect(popup.shown.last?.rows.first?.detail == "now")
        #expect(popup.shown.last?.rows.first?.icon == .file("/Users/test/a.pdf"))
        #expect(popup.shown.last?.canDelete == true)
    }

    @Test func skippedCopiesArentKept() async throws {
        let module = try await started()
        clipboard.copy(.skipped("org.nspasteboard.ConcealedType"))
        module.perform(.module("clipboard"))
        #expect(titles.isEmpty)
    }

    @Test func pickingAnEntryPutsItBackAndPastes() async throws {
        let module = try await started()
        clipboard.copy(.copied(.text("one", rtf: nil)))
        clipboard.copy(.copied(.text("two", rtf: nil)))
        module.perform(.module("clipboard"))
        popup.send(.clicked(1))
        #expect(clipboard.put.map(\.0.text) == ["one"])
        #expect(clipboard.pastes == 1)
        module.perform(.module("clipboard"))
        #expect(titles == ["one", "two"])
    }

    @Test func pasteOffOnlyPutsItBack() async throws {
        let module = try await started(["paste": .boolean(false)])
        clipboard.copy(.copied(.text("one", rtf: nil)))
        module.perform(.module("clipboard"))
        popup.send(.command(.choose))
        #expect(clipboard.put.count == 1)
        #expect(clipboard.pastes == 0)
    }

    @Test func imagesGoBackWithTheirBytes() async throws {
        let module = try await started()
        clipboard.copy(.copied(.image(png: Data([1, 2, 3]))))
        module.perform(.module("clipboard"))
        #expect(titles == ["Image"])
        popup.send(.command(.choose))
        #expect(clipboard.put.first?.1 == Data([1, 2, 3]))
    }

    @Test func deleteAndClearAll() async throws {
        let module = try await started()
        for text in ["a", "b", "c"] { clipboard.copy(.copied(.text(text, rtf: nil))) }
        module.perform(.module("clipboard"))
        popup.send(.deleteClicked(0))
        #expect(titles == ["b", "a"])
        popup.send(.clearAll)
        #expect(titles.isEmpty)
    }

    @Test func historySurvivesARestart() async throws {
        let module = try await started()
        clipboard.copy(.copied(.text("kept", rtf: nil)))
        await module.stop()
        let again = try await started()
        again.perform(.module("clipboard"))
        #expect(titles == ["kept"])
    }

    @Test func smallerSizeDropsTheOldest() async throws {
        let module = try await started()
        for text in ["a", "b", "c"] { clipboard.copy(.copied(.text(text, rtf: nil))) }
        module.apply(["size": .integer(2)])
        module.perform(.module("clipboard"))
        #expect(titles == ["c", "b"])
    }

    @Test func deniedClipboardIsDegraded() async throws {
        clipboard.isDenied = true
        let module = try await started()
        guard case .degraded = module.status else {
            Issue.record("expected degraded, got \(module.status)")
            return
        }
        clipboard.isDenied = false
        module.check()
        #expect(module.status == .running)
    }

    @Test func stopStopsRecording() async throws {
        let module = try await started()
        await module.stop()
        #expect(!clipboard.isWatching)
        #expect(module.status == .off)
    }

    @Test func agesAreShort() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let ages = [30.0, 300, 7_200, 172_800].map { ClipboardList.age(since: now.addingTimeInterval(-$0), now: now) }
        #expect(ages == ["now", "5m", "2h", "2d"])
    }
}
