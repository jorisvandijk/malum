import Foundation
import Testing

@testable import MalumCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
struct ScreenshotSessionTests {
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 600)
    private let colors = ScreenshotColor.quickDefaults

    private func session() -> ScreenshotSession {
        ScreenshotSession(screen: screen, quickColors: colors)
    }

    /// Drags from `start` to `end` in overlay points.
    private func drag(_ session: inout ScreenshotSession, _ start: CGPoint, _ end: CGPoint) {
        _ = session.press(at: start)
        _ = session.move(to: end)
        _ = session.release(at: end)
    }

    @Test func aSelectDragCropsAndCentersThePart() {
        var shot = session()
        _ = shot.press(at: CGPoint(x: 100, y: 100))
        _ = shot.move(to: CGPoint(x: 300, y: 200))
        #expect(shot.selection == CGRect(x: 100, y: 100, width: 200, height: 100))
        _ = shot.release(at: CGPoint(x: 300, y: 200))
        #expect(shot.edits.crop == CGRect(x: 100, y: 100, width: 200, height: 100))
        #expect(shot.viewport.shown == CGRect(x: 400, y: 250, width: 200, height: 100))
        #expect(shot.selection == nil && shot.drag == nil)
    }

    @Test func drawingAfterACropLandsInShotPoints() {
        var shot = session()
        drag(&shot, CGPoint(x: 100, y: 100), CGPoint(x: 300, y: 200))
        _ = shot.perform(.tool(.line))
        drag(&shot, CGPoint(x: 400, y: 250), CGPoint(x: 600, y: 350))
        let red = colors.first ?? ScreenshotColor(red: 0, green: 0, blue: 0)
        let line = Annotation.Shape.line(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 300, y: 200))
        #expect(shot.edits.annotations == [Annotation(line, color: red, size: .medium)])
    }

    @Test func aDragShowsItsShapeUntilReleased() {
        var shot = session()
        _ = shot.perform(.tool(.rectangle))
        _ = shot.press(at: CGPoint(x: 10, y: 10))
        _ = shot.move(to: CGPoint(x: 20, y: 30))
        #expect(shot.preview?.shape == .rectangle(CGRect(x: 10, y: 10, width: 10, height: 20)))
        #expect(shot.edits.annotations.isEmpty)
        _ = shot.release(at: CGPoint(x: 20, y: 30))
        #expect(shot.preview == nil && shot.edits.annotations.count == 1)
    }

    @Test func textIsTypedAndEndsWithAClickOrEscape() {
        var shot = session()
        _ = shot.perform(.tool(.text))
        _ = shot.press(at: CGPoint(x: 50, y: 60))
        #expect(shot.isTyping)
        _ = shot.type("Hix")
        _ = shot.deleteBackward()
        _ = shot.type("!")
        #expect(shot.preview?.shape == .text("Hi!", at: CGPoint(x: 50, y: 60)))
        #expect(shot.perform(.cancel) == .redraw)
        #expect(!shot.isTyping && shot.edits.annotations.map(\.shape) == [.text("Hi!", at: CGPoint(x: 50, y: 60))])
        _ = shot.press(at: CGPoint(x: 1, y: 1))
        _ = shot.type("x")
        #expect(shot.press(at: CGPoint(x: 2, y: 2)) == .redraw)
        #expect(!shot.isTyping && shot.edits.annotations.count == 2)
    }

    @Test func emptyTextAddsNothingAndEnterWhileTypingSaves() {
        var shot = session()
        _ = shot.perform(.tool(.text))
        _ = shot.press(at: .zero)
        #expect(shot.perform(.save) == .save)
        #expect(shot.edits.annotations.isEmpty && !shot.isTyping)
    }

    @Test func typingWithoutTextDoesNothing() {
        var shot = session()
        #expect(shot.type("a") == .unchanged && shot.deleteBackward() == .unchanged)
    }

    @Test func saveCancelAndPickerAreForTheOverlay() {
        var shot = session()
        #expect(shot.perform(.save) == .save)
        #expect(shot.perform(.cancel) == .cancel)
        #expect(shot.perform(.colorPicker) == .openColorPicker)
    }

    @Test func undoingACropShowsTheWholeScreenAgainButUndoingADrawingKeepsTheZoom() {
        var shot = session()
        _ = shot.perform(.tool(.line))
        drag(&shot, .zero, CGPoint(x: 10, y: 10))
        _ = shot.perform(.zoomIn)
        _ = shot.perform(.undo)
        #expect(shot.edits.annotations.isEmpty && shot.viewport.scale > 1)
        _ = shot.perform(.resetZoom)
        _ = shot.perform(.tool(.select))
        drag(&shot, .zero, CGPoint(x: 10, y: 10))
        _ = shot.perform(.undo)
        #expect(shot.edits.crop == screen && shot.viewport.scale == 1)
        _ = shot.perform(.redo)
        #expect(shot.edits.crop == CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    @Test func zoomScrollAndResetChangeOnlyTheView() {
        var shot = session()
        _ = shot.zoom(by: 2, at: .zero)
        _ = shot.scroll(by: CGPoint(x: 5, y: 5))
        #expect(shot.viewport.scale == 2)
        _ = shot.perform(.resetZoom)
        #expect(shot.viewport.shown == screen && shot.edits == ScreenshotEdits(screen: screen))
    }

    @Test func aPickedColorIsUsedNext() {
        var shot = session()
        let picked = ScreenshotColor(red: 1, green: 2, blue: 3)
        _ = shot.pick(picked)
        _ = shot.perform(.tool(.arrow))
        drag(&shot, .zero, CGPoint(x: 5, y: 0))
        #expect(shot.edits.annotations.first?.color == picked)
    }

    @Test func toolbarCommandsSayWhetherTheyChangedAnything() {
        var shot = session()
        #expect(shot.perform(.larger) == .redraw)
        #expect(shot.perform(.quickColor(99)) == .unchanged)
        #expect(shot.move(to: .zero) == .unchanged && shot.release(at: .zero) == .unchanged)
    }
}
