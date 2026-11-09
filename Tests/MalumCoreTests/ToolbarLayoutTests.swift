import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ToolbarLayoutTests {
    @Test func groupsHoldEveryCommandWithAButton() {
        let groups = ToolbarLayout.groups(quickColors: 3)
        #expect(groups.count == 6)
        #expect(
            groups[2] == [
                .button(.quickColor(0)), .button(.quickColor(1)), .button(.quickColor(2)), .button(.colorPicker),
            ])
        #expect(
            groups[1] == [
                .button(.tool(.line)), .button(.tool(.arrow)), .button(.tool(.rectangle)), .button(.tool(.text)),
            ])
        #expect(groups[3] == [.button(.smaller), .currentSize, .button(.larger)])
    }

    @Test func pickedToolAndColorShowAsPicked() {
        var toolbar = ScreenshotToolbar(quickColors: ScreenshotColor.quickDefaults)
        _ = toolbar.perform(.tool(.arrow))
        _ = toolbar.perform(.quickColor(2))
        #expect(ToolbarLayout.isPicked(.tool(.arrow), in: toolbar))
        #expect(!ToolbarLayout.isPicked(.tool(.line), in: toolbar))
        #expect(ToolbarLayout.isPicked(.quickColor(2), in: toolbar))
        #expect(!ToolbarLayout.isPicked(.undo, in: toolbar))
    }

    @Test func keyLabelsShowWhatsOnTheKeys() {
        #expect(ToolbarLayout.keyLabel(of: .tool(.line)) == "L")
        #expect(ToolbarLayout.keyLabel(of: .smaller) == "[")
        #expect(ToolbarLayout.keyLabel(of: .quickColor(0)) == "1")
        #expect(ToolbarLayout.keyLabel(of: .redo) == "⇧⌘Z")
        #expect(ToolbarLayout.keyLabel(of: .save) == "↩")
        #expect(ToolbarLayout.keyLabel(of: .cancel) == "esc")
    }

    @Test func everyButtonHasAName() {
        for item in ToolbarLayout.groups(quickColors: ScreenshotsConfig.maxColors).joined() {
            guard case .button(let command) = item else { continue }
            #expect(!ScreenshotWords.name(of: command).isEmpty)
        }
        #expect(ScreenshotWords.name(of: .quickColor(0)) == "Color 1")
    }
}
