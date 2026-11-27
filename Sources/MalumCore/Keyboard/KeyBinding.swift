/// One shortcut from `keyboard.toml`: a key pressed with modifiers, and what it does.
struct KeyBinding: Equatable, Sendable {
    /// The key and the modifiers held with it.
    let hotkey: Hotkey
    /// What it does.
    let action: KeyAction
    /// The shortcut as `keyboard.toml` writes it, such as `ctrl+cmd+h`.
    let written: String

    /// Creates the shortcut `hotkey`, which does `action`, written `written` in `keyboard.toml`, by
    /// default in the shared syntax.
    init(hotkey: Hotkey, action: KeyAction, written: String? = nil) {
        self.hotkey = hotkey
        self.action = action
        self.written = written ?? hotkey.description
    }

    /// The key path the shortcut is written at in `keyboard.toml`, such as `shortcuts."hyper+space"`.
    var path: [String] { [KeyboardCatalog.shortcutsTable, written] }
}
