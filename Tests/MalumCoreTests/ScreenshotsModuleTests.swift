import Foundation
import Testing

@testable import MalumCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ScreenshotsModuleTests {
    private let paths = Paths(home: "/Users/test")
    private let files = FakeFileSystem()
    private let clipboard = FakeClipboard()
    private let capture = FakeScreenCapture()
    private let overlay = FakeScreenshotOverlay()
    private let writer = RecordingLogWriter()
    /// 2026-11-09 20:14:09 UTC, in the time zone the tests run in.
    private let date = Date(timeIntervalSince1970: 1_794_255_249)

    private var stamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

    private func started(_ settings: ModuleSettings = [:]) async throws -> ScreenshotsModule {
        let system = ScreenshotsSystem(
            files: files, paths: paths, capture: capture, overlay: overlay, clipboard: clipboard)
        let module = ScreenshotsModule(system: system, log: Log(writer: writer)) { [date] in date }
        module.apply(settings)
        try await module.start()
        return module
    }

    /// Takes a shot and waits for it.
    private func shoot(_ module: ScreenshotsModule) async {
        module.perform(.module("screenshot"))
        await module.shot?.value
    }

    private func text(at path: String) -> String? {
        try? files.read(path)  // A missing file is an expected answer here.
    }

    @Test func offersTheScreenshotActionAndNeedsScreenRecording() async throws {
        let module = try await started()
        #expect(module.hotkeys == HotkeyOffer(actions: ["screenshot"]))
        #expect(module.permissions == [.screenRecording])
        #expect(module.status == .running)
    }

    @Test func aPlainShotIsSavedToDocumentsAndCopied() async throws {
        overlay.result = { $0 }
        await shoot(try await started())
        let path = "/Users/test/Documents/malum-ss-\(stamp).png"
        #expect(text(at: path) == "1000x600 with 0")
        #expect(text(at: "/Users/test/Documents/malum-ss-\(stamp)-annotated.png") == nil)
        #expect(clipboard.put.count == 1)
        #expect(clipboard.put.first?.0.kind == .image)
        #expect(clipboard.put.first?.1 == Data("1000x600 with 0".utf8))
    }

    @Test func anAnnotatedShotSavesBothAndCopiesTheAnnotatedOne() async throws {
        overlay.result = { edits in
            var edited = edits
            edited.select(CGRect(x: 0, y: 0, width: 200, height: 100))
            edited.add(
                Annotation(
                    .line(from: .zero, to: CGPoint(x: 5, y: 5)), color: .init(red: 0, green: 0, blue: 0), size: .small))
            return edited
        }
        await shoot(try await started())
        #expect(text(at: "/Users/test/Documents/malum-ss-\(stamp).png") == "200x100 with 0")
        #expect(text(at: "/Users/test/Documents/malum-ss-\(stamp)-annotated.png") == "200x100 with 1")
        #expect(clipboard.put.first?.1 == Data("200x100 with 1".utf8))
    }

    @Test func cancellingSavesNothing() async throws {
        await shoot(try await started())
        #expect(files.item(at: "/Users/test/Documents/malum-ss-\(stamp).png") == nil)
        #expect(clipboard.put.isEmpty)
    }

    @Test func theFolderAndColorsComeFromTheSettings() async throws {
        overlay.result = { $0 }
        let settings: ModuleSettings = ["folder": .string("~/Shots"), "colors": .array([.string("#00ff00")])]
        await shoot(try await started(settings))
        #expect(text(at: "/Users/test/Shots/malum-ss-\(stamp).png") != nil)
        #expect(overlay.opened == [[ScreenshotColor(red: 0, green: 255, blue: 0)]])
    }

    @Test func aFailedFreezeIsLoggedAndOpensNothing() async throws {
        capture.error = .noScreen
        await shoot(try await started())
        #expect(overlay.opened.isEmpty)
        #expect(writer.entries.map(\.text.description).contains { $0.contains("no screen is under the mouse") })
    }

    @Test func aRefusedClipboardIsLoggedButTheShotStaysSaved() async throws {
        overlay.result = { $0 }
        clipboard.refusesPut = true
        await shoot(try await started())
        #expect(text(at: "/Users/test/Documents/malum-ss-\(stamp).png") != nil)
        #expect(writer.entries.map(\.text.description).contains { $0.contains("put the screenshot on the clipboard") })
    }

    @Test func otherActionsDoNothing() async throws {
        let module = try await started()
        module.perform(.module("launcher"))
        #expect(module.shot == nil && capture.freezes == 0)
    }
}
