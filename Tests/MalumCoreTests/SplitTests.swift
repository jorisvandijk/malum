import Foundation
import Testing

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
struct SplitTests {
    @Test func startsEvenWithEqualRows() {
        let split = Split()
        #expect(split.left == 0.5)
        #expect(split.rowShares(count: 3) == nil)
    }

    @Test func dividerMovesByTheStepAndStopsAtTheLimits() {
        var split = Split()
        split.moveDivider(by: 0.05)
        #expect(split.left == 0.55)
        split.moveDivider(by: -0.05)
        #expect(split.left == 0.5)
        split.moveDivider(by: 0.5)
        #expect(split.left == 0.8)
        split.moveDivider(by: -1)
        #expect(split.left == 0.2)
    }

    @Test func tallerRowTakesFromTheOthersBySpare() {
        var split = Split()
        split.resizeRow(0, of: 2, by: 0.1)
        #expect(split.rowShares(count: 2) == [0.6, 0.4])
        split.resizeRow(0, of: 2, by: 0.5)
        #expect(split.rowShares(count: 2) == [0.8, 0.2])
    }

    @Test func shorterRowGivesToTheOthersEqually() {
        var split = Split()
        split.resizeRow(1, of: 3, by: -0.1)
        let shares = split.rowShares(count: 3) ?? []
        #expect(shares.count == 3)
        #expect(abs((shares.first ?? 0) - 0.3833) < 0.001)
        #expect(abs(shares[1] - 0.2333) < 0.001)
        #expect(abs(shares.reduce(0, +) - 1) < 0.001)
    }

    @Test func noRowGoesBelowTheFloor() {
        var split = Split()
        split.resizeRow(1, of: 2, by: -1)
        #expect(split.rowShares(count: 2) == [0.8, 0.2])
        #expect(Split.floor(count: 10) == 0.05)
    }

    @Test func rowsSetForAnotherCountAreEqualAgain() {
        var split = Split()
        split.resizeRow(0, of: 2, by: 0.1)
        #expect(split.rowShares(count: 3) == nil)
    }

    @Test func aSingleRowOrOneOutOfRangeChangesNothing() {
        var split = Split()
        split.resizeRow(0, of: 1, by: 0.1)
        split.resizeRow(2, of: 2, by: 0.1)
        #expect(split == Split())
    }

    @Test func rowBorderMovesOnlyTheTwoRowsBesideIt() {
        var split = Split()
        split.moveRowBorder(0, of: 3, by: 0.1)
        #expect(split.rowShares(count: 3).map { $0.map { ($0 * 10_000).rounded() } } == [4333, 2334, 3333])
        split.moveRowBorder(0, of: 3, by: -0.1)
        #expect(split.rowShares(count: 3).map { $0.map { ($0 * 10_000).rounded() } } == [3333, 3334, 3333])
    }

    @Test func rowBorderStopsAtTheFloor() {
        var split = Split()
        split.moveRowBorder(0, of: 2, by: 0.9)
        #expect(split.rowShares(count: 2) == [0.8, 0.2])
        split.moveRowBorder(0, of: 2, by: -0.9)
        #expect(split.rowShares(count: 2) == [0.2, 0.8])
    }

    @Test func rowBorderOutOfRangeChangesNothing() {
        var split = Split()
        split.moveRowBorder(1, of: 2, by: 0.1)
        split.moveRowBorder(0, of: 1, by: 0.1)
        #expect(split == Split())
    }
}
