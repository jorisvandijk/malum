import Foundation
import Testing

@testable import MalumCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
struct ArrowHeadTests {
    @Test func headPointsAlongTheArrowWithItsTipAtTheEnd() {
        let corners = ArrowHead.corners(from: .zero, to: CGPoint(x: 100, y: 0), lineWidth: 4)
        #expect(corners == [CGPoint(x: 100, y: 0), CGPoint(x: 84, y: 6.4), CGPoint(x: 84, y: -6.4)])
    }

    @Test func thinArrowsKeepAVisibleHead() {
        let corners = ArrowHead.corners(from: .zero, to: CGPoint(x: 0, y: 100), lineWidth: 1)
        #expect(corners.dropFirst().allSatisfy { $0.y == 88 })
    }

    @Test func aShortArrowIsAllHead() {
        let corners = ArrowHead.corners(from: .zero, to: CGPoint(x: 5, y: 0), lineWidth: 4)
        #expect(corners.dropFirst().allSatisfy { $0.x == 0 })
    }

    @Test func noLengthGivesNoHead() {
        #expect(ArrowHead.corners(from: .zero, to: .zero, lineWidth: 4).isEmpty)
    }

    @Test func errorsSayWhatFailed() {
        #expect(ScreenshotError.noScreen.text == "couldn't take a screenshot: no screen is under the mouse")
        #expect(ScreenshotError.captureFailed("denied").text == "couldn't take a screenshot: denied")
        #expect(ScreenshotError.unencodable.text == "couldn't save the screenshot: it couldn't be made into a PNG")
    }
}
