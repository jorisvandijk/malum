/// The screenshot toolbar's words: each button's name for its tooltip, the key labels under the
/// buttons, and the size shown between the size buttons.
public enum ScreenshotWords {
    /// How the keys whose names aren't what's printed on them are shown, by `Key` name.
    private static let keySymbols = [
        "open_bracket": "[", "close_bracket": "]", "equal": "=", "minus": "-", "return": "↩", "escape": "esc",
    ]
    /// How the modifiers are shown in front of a key, in the order macOS shows them.
    private static let modifierSymbols: [(modifier: Modifier, symbol: String)] = [
        (.ctrl, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.cmd, "⌘"),
    ]
    /// What shows a line's width: a dot drawn at the line's size.
    public static let lineSample = "●"
    /// What shows a text size: a letter drawn at that size.
    public static let textSample = "A"

    /// The label of `hotkey` under its button, such as `L`, `[` or `⇧⌘Z`.
    static func keyLabel(_ hotkey: Hotkey) -> String {
        let modifiers = modifierSymbols.filter { hotkey.modifiers.contains($0.modifier) }.map(\.symbol)
        let key = keySymbols[hotkey.key.name] ?? hotkey.key.name.uppercased()
        return modifiers.joined() + key
    }

    /// The names of the buttons that aren't a tool or a quick color.
    private static let names: [ScreenshotCommand: String] = [
        .colorPicker: "Pick a color", .smaller: "Thinner or smaller", .larger: "Thicker or bigger",
        .moveToolbar: "Move the toolbar", .zoomIn: "Zoom in", .zoomOut: "Zoom out", .resetZoom: "Real size",
        .undo: "Undo", .redo: "Redo", .save: "Save", .cancel: "Cancel",
    ]

    /// The name of `command`'s button, for its tooltip.
    public static func name(of command: ScreenshotCommand) -> String {
        switch command {
        case .tool(let tool):
            name(of: tool)
        case .quickColor(let index):
            "Color \(index + 1)"
        default:
            names[command] ?? ""
        }
    }

    /// The name of `tool`.
    private static func name(of tool: ScreenshotTool) -> String {
        switch tool {
        case .select: "Select"
        case .line: "Line"
        case .arrow: "Arrow"
        case .rectangle: "Rectangle"
        case .text: "Text"
        }
    }
}
