import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ScreenshotToolbarTests {
    private let colors = ScreenshotColor.quickDefaults

    @Test func aShotStartsWithSelectFirstColorMediumAtTheTop() {
        let toolbar = ScreenshotToolbar(quickColors: colors)
        #expect(toolbar.tool == .select && toolbar.color == colors.first && toolbar.size == .medium)
        #expect(!toolbar.isAtBottom && toolbar.quickColorIndex == 0)
    }

    @Test func commandsChangeToolColorSizeAndPlace() {
        var toolbar = ScreenshotToolbar(quickColors: colors)
        let commands: [ScreenshotCommand] = [.tool(.arrow), .quickColor(4), .larger, .larger, .smaller, .moveToolbar]
        let done = commands.map { toolbar.perform($0) }
        #expect(done.allSatisfy { $0 })
        #expect(toolbar.tool == .arrow && toolbar.quickColorIndex == 4 && toolbar.size == .medium)
        #expect(toolbar.isAtBottom)
        _ = toolbar.perform(.moveToolbar)
        #expect(!toolbar.isAtBottom)
    }

    @Test func aMissingQuickColorChangesNothing() {
        var toolbar = ScreenshotToolbar(quickColors: Array(colors.prefix(2)))
        let done = toolbar.perform(.quickColor(2))
        #expect(!done && toolbar.quickColorIndex == 0)
    }

    @Test func aPickedColorIsNoQuickColor() {
        var toolbar = ScreenshotToolbar(quickColors: colors)
        toolbar.color = ScreenshotColor(red: 1, green: 2, blue: 3)
        #expect(toolbar.quickColorIndex == nil)
    }

    @Test func overlayCommandsAreLeftToTheOverlay() {
        var toolbar = ScreenshotToolbar(quickColors: colors)
        let commands: [ScreenshotCommand] = [.undo, .redo, .save, .cancel, .zoomIn, .zoomOut, .resetZoom, .colorPicker]
        let done = commands.map { toolbar.perform($0) }
        #expect(done.allSatisfy { !$0 })
        #expect(toolbar == ScreenshotToolbar(quickColors: colors))
    }

    @Test func sizesGrowWithTheirSteps() {
        let sizes = AnnotationSize.allCases
        #expect(sizes.map(\.lineWidth) == sizes.map(\.lineWidth).sorted())
        #expect(sizes.map(\.textSize) == sizes.map(\.textSize).sorted())
        #expect(AnnotationSize.small.smaller == .small && AnnotationSize.large.larger == .large)
    }
}
