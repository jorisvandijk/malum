/// The keys of the screenshot overlay: one table that both the overlay's key handling and the
/// toolbar's labels read, so a button always shows the key that does the same.
public enum ScreenshotKeys {
    /// Each command with its key, nil only if a name isn't in `Key`'s table.
    private static let table: [(command: ScreenshotCommand, hotkey: Hotkey?)] =
        [
            (.tool(.select), hotkey("s")), (.tool(.line), hotkey("l")), (.tool(.arrow), hotkey("a")),
            (.tool(.rectangle), hotkey("r")), (.tool(.text), hotkey("t")), (.colorPicker, hotkey("p")),
            (.smaller, hotkey("open_bracket")), (.larger, hotkey("close_bracket")), (.moveToolbar, hotkey("b")),
            (.zoomIn, hotkey("equal")), (.zoomOut, hotkey("minus")), (.resetZoom, hotkey("0")),
            (.undo, hotkey("z", [.cmd])), (.redo, hotkey("z", [.cmd, .shift])),
            (.save, hotkey("return")), (.cancel, hotkey("escape")),
        ] + (1...ScreenshotsConfig.maxColors).map { (.quickColor($0 - 1), hotkey(String($0))) }

    /// Every key with what it does.
    private static let commands: [Hotkey: ScreenshotCommand] = Dictionary(
        table.compactMap { row in row.hotkey.map { ($0, row.command) } }, uniquingKeysWith: { first, _ in first })

    /// What the key with virtual key code `keyCode`, pressed with `modifiers`, does, or nil when it
    /// does nothing in the overlay.
    public static func command(keyCode: UInt16, modifiers: Set<Modifier>) -> ScreenshotCommand? {
        guard let key = Key.coded(keyCode) else { return nil }
        return commands[Hotkey(modifiers: modifiers, key: key)]
    }

    /// The key that does `command`, for its toolbar button, or nil when no key does.
    static func hotkey(for command: ScreenshotCommand) -> Hotkey? {
        table.first { $0.command == command }?.hotkey
    }

    /// The key called `name` in `Key`'s table, pressed with `modifiers`.
    private static func hotkey(_ name: String, _ modifiers: Set<Modifier> = []) -> Hotkey? {
        Key.named(name).map { Hotkey(modifiers: modifiers, key: $0) }
    }
}
