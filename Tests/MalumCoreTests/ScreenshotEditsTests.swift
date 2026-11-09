import Foundation
import Testing

@testable import MalumCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
struct ScreenshotEditsTests {
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 600)
    private let red = ScreenshotColor(red: 255, green: 0, blue: 0)

    private func line(_ length: Double) -> Annotation {
        Annotation(.line(from: .zero, to: CGPoint(x: length, y: 0)), color: red, size: .medium)
    }

    @Test func aNewShotKeepsTheWholeScreenAndHasNothingDrawn() {
        let edits = ScreenshotEdits(screen: screen)
        #expect(edits.crop == screen)
        #expect(!edits.isAnnotated && !edits.canUndo && !edits.canRedo)
    }

    @Test func undoAndRedoGoThroughDrawingsAndCropsInOrder() {
        var edits = ScreenshotEdits(screen: screen)
        let part = CGRect(x: 100, y: 100, width: 200, height: 100)
        edits.add(line(10))
        edits.select(part)
        edits.add(line(20))
        #expect(edits.annotations == [line(10), line(20)] && edits.crop == part)
        edits.undo()
        edits.undo()
        #expect(edits.annotations == [line(10)] && edits.crop == screen)
        edits.redo()
        #expect(edits.crop == part && edits.annotations == [line(10)])
    }

    @Test func aNewStepClearsRedo() {
        var edits = ScreenshotEdits(screen: screen)
        edits.add(line(10))
        edits.undo()
        edits.add(line(20))
        #expect(!edits.canRedo)
        edits.redo()
        #expect(edits.annotations == [line(20)])
    }

    @Test func aSelectionIsClippedToTheScreen() {
        var edits = ScreenshotEdits(screen: screen)
        edits.select(CGRect(x: 900, y: 500, width: 300, height: 300))
        #expect(edits.crop == CGRect(x: 900, y: 500, width: 100, height: 100))
    }

    @Test func anEmptyOrOutsideSelectionDoesNothing() {
        var edits = ScreenshotEdits(screen: screen)
        edits.select(CGRect(x: 10, y: 10, width: 0, height: 50))
        edits.select(CGRect(x: 2000, y: 0, width: 50, height: 50))
        edits.select(screen)
        #expect(edits.crop == screen && !edits.canUndo)
    }

    @Test func undoWithNothingDoneDoesNothing() {
        var edits = ScreenshotEdits(screen: screen)
        edits.undo()
        edits.redo()
        #expect(edits == ScreenshotEdits(screen: screen))
    }

    @Test func dragsMakeTheToolsShapes() {
        let start = CGPoint(x: 50, y: 40)
        let end = CGPoint(x: 10, y: 80)
        #expect(Annotation.dragged(.line, from: start, to: end) == .line(from: start, to: end))
        #expect(Annotation.dragged(.arrow, from: start, to: end) == .arrow(from: start, to: end))
        #expect(
            Annotation.dragged(.rectangle, from: start, to: end)
                == .rectangle(CGRect(x: 10, y: 40, width: 40, height: 40)))
        #expect(Annotation.dragged(.select, from: start, to: end) == nil)
        #expect(Annotation.dragged(.text, from: start, to: end) == nil)
        #expect(Annotation.dragged(.line, from: start, to: start) == nil)
    }
}
