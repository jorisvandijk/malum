import Foundation
import Testing

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
struct SplitDragTests {
    private let area = CGRect(x: 0, y: 25, width: 1000, height: 900)

    @Test func sidewaysMovesTheDividerByItsShareOfTheWidth() throws {
        let drag = try #require(SplitDrag(at: CGPoint(x: 200, y: 300), in: area, split: Split(), count: 2))
        var expected = Split()
        expected.moveDivider(by: 0.1)
        #expect(drag.split(at: CGPoint(x: 300, y: 600)) == expected)
        #expect(drag.split(at: CGPoint(x: 200, y: 300)) == Split())
    }

    @Test func dividerStopsAtTheLimits() throws {
        let drag = try #require(SplitDrag(at: CGPoint(x: 500, y: 300), in: area, split: Split(), count: 2))
        #expect(drag.split(at: CGPoint(x: 0, y: 300)).left == Split.minimum)
        #expect(drag.split(at: CGPoint(x: 1000, y: 300)).left == 1 - Split.minimum)
    }

    @Test func inTheRightColumnUpAndDownMovesTheNearestRowBorder() throws {
        // Three rows of 300 on the right: borders at 325 and 625. 600 is nearest the second.
        let drag = try #require(SplitDrag(at: CGPoint(x: 700, y: 600), in: area, split: Split(), count: 4))
        var expected = Split()
        expected.moveRowBorder(1, of: 3, by: 0.1)
        #expect(drag.split(at: CGPoint(x: 700, y: 690)) == expected)
    }

    @Test func inTheLeftColumnUpAndDownMovesNothing() throws {
        let drag = try #require(SplitDrag(at: CGPoint(x: 100, y: 600), in: area, split: Split(), count: 4))
        #expect(drag.split(at: CGPoint(x: 100, y: 800)) == Split())
    }

    @Test func aSingleRowHasNoBorderToMove() throws {
        let drag = try #require(SplitDrag(at: CGPoint(x: 700, y: 600), in: area, split: Split(), count: 2))
        #expect(drag.split(at: CGPoint(x: 700, y: 800)) == Split())
    }

    @Test func aSingleWindowHasNoDrag() {
        #expect(SplitDrag(at: CGPoint(x: 100, y: 100), in: area, split: Split(), count: 1) == nil)
    }
}
