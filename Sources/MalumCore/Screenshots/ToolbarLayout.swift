/// One place in the screenshot toolbar.
public enum ToolbarItem: Equatable, Sendable {
    /// A button that runs a command.
    case button(ScreenshotCommand)
    /// The current line width or text size, between the smaller and larger buttons.
    case currentSize
}

/// The screenshot toolbar's groups, left to right, each shown as one rounded panel.
public enum ToolbarLayout {
    /// The groups for a toolbar with `quickColors` quick colors.
    public static func groups(quickColors: Int) -> [[ToolbarItem]] {
        [
            [.button(.tool(.select)), .button(.zoomIn), .button(.zoomOut)],
            ScreenshotTool.allCases.filter { $0 != .select }.map { .button(.tool($0)) },
            (0..<quickColors).map { .button(.quickColor($0)) } + [.button(.colorPicker)],
            [.button(.smaller), .currentSize, .button(.larger)],
            [.button(.undo), .button(.redo)],
            [.button(.moveToolbar), .button(.cancel), .button(.save)],
        ]
    }

    /// Whether `command`'s button shows as picked in `toolbar`.
    public static func isPicked(_ command: ScreenshotCommand, in toolbar: ScreenshotToolbar) -> Bool {
        switch command {
        case .tool(let tool):
            tool == toolbar.tool
        case .quickColor(let index):
            index == toolbar.quickColorIndex
        default:
            false
        }
    }

    /// The label under `command`'s button: the key that does the same, or empty when none does.
    public static func keyLabel(of command: ScreenshotCommand) -> String {
        ScreenshotKeys.hotkey(for: command).map(ScreenshotWords.keyLabel) ?? ""
    }
}
