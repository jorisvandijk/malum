/// One shortcut from `keyboard.toml`: a key pressed with modifiers, and what it does.
struct KeyBinding: Equatable, Sendable {
    /// The key and the modifiers held with it.
    let hotkey: Hotkey
    /// What it does.
    let action: KeyAction

    /// The key path the shortcut is written at in `keyboard.toml`, such as `hyper.space`.
    var path: [String] { [Modifier.table(of: hotkey.modifiers), hotkey.key.name] }
}
