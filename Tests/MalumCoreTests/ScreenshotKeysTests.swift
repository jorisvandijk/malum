import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ScreenshotKeysTests {
    private func command(_ name: String, _ modifiers: Set<Modifier> = []) -> ScreenshotCommand? {
        guard let key = Key.named(name) else { return nil }
        return ScreenshotKeys.command(keyCode: key.keyCode, modifiers: modifiers)
    }

    @Test func lettersPickTools() {
        #expect(command("s") == .tool(.select))
        #expect(command("l") == .tool(.line))
        #expect(command("a") == .tool(.arrow))
        #expect(command("r") == .tool(.rectangle))
        #expect(command("t") == .tool(.text))
    }

    @Test func numbersPickQuickColorsFromZero() {
        #expect(command("1") == .quickColor(0))
        #expect(command("7") == .quickColor(6))
        #expect(command("8") == nil)
    }

    @Test func undoRedoSaveAndCancel() {
        #expect(command("z", [.cmd]) == .undo)
        #expect(command("z", [.cmd, .shift]) == .redo)
        #expect(command("z") == nil)
        #expect(command("return") == .save)
        #expect(command("escape") == .cancel)
    }

    @Test func everyCommandHasOneKey() {
        let all: [ScreenshotCommand] =
            ScreenshotTool.allCases.map { .tool($0) } + (0..<ScreenshotsConfig.maxColors).map { .quickColor($0) }
            + [
                .colorPicker, .smaller, .larger, .moveToolbar, .zoomIn, .zoomOut, .resetZoom, .undo, .redo, .save,
                .cancel,
            ]
        for each in all {
            let hotkey = ScreenshotKeys.hotkey(for: each)
            #expect(hotkey != nil)
            #expect(hotkey.flatMap { ScreenshotKeys.command(keyCode: $0.key.keyCode, modifiers: $0.modifiers) } == each)
        }
    }

    @Test func onlySaveCancelUndoAndRedoWorkWhileTyping() {
        #expect(ScreenshotKeys.worksWhileTyping(.save) && ScreenshotKeys.worksWhileTyping(.redo))
        #expect(!ScreenshotKeys.worksWhileTyping(.tool(.line)) && !ScreenshotKeys.worksWhileTyping(nil))
    }

    @Test func deleteKeyDeletesBackward() {
        #expect(ScreenshotKeys.deletesBackward(keyCode: Key.named("delete")?.keyCode ?? 0))
        #expect(!ScreenshotKeys.deletesBackward(keyCode: Key.named("a")?.keyCode ?? 0))
    }
}
