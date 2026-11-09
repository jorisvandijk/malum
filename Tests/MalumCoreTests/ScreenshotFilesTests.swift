import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ScreenshotFilesTests {
    /// 2026-11-09 20:14:09 UTC.
    private let date = Date(timeIntervalSince1970: 1_794_255_249)
    private let utc = TimeZone(identifier: "UTC") ?? .current
    private let folder = "/Users/test/Documents"

    @Test func namesHoldTheDateAndTime() {
        let files = ScreenshotFiles.next(at: date, in: folder, timeZone: utc) { _ in false }
        #expect(files.plain == "/Users/test/Documents/malum-ss-2026-11-09_20-14-09.png")
        #expect(files.annotated == "/Users/test/Documents/malum-ss-2026-11-09_20-14-09-annotated.png")
    }

    @Test func timeIsLocal() {
        let amsterdam = TimeZone(identifier: "Europe/Amsterdam") ?? utc
        let files = ScreenshotFiles.next(at: date, in: folder, timeZone: amsterdam) { _ in false }
        #expect(files.plain.hasSuffix("malum-ss-2026-11-09_21-14-09.png"))
    }

    @Test func aTakenNameMovesBothToTheNextNumber() {
        let taken: Set = [
            "/Users/test/Documents/malum-ss-2026-11-09_20-14-09.png",
            "/Users/test/Documents/malum-ss-2026-11-09_20-14-09-2-annotated.png",
        ]
        let files = ScreenshotFiles.next(at: date, in: folder, timeZone: utc) { taken.contains($0) }
        #expect(files.plain == "/Users/test/Documents/malum-ss-2026-11-09_20-14-09-3.png")
        #expect(files.annotated == "/Users/test/Documents/malum-ss-2026-11-09_20-14-09-3-annotated.png")
    }
}
