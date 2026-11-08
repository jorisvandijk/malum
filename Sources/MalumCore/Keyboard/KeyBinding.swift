/// One shortcut from `keyboard.toml`: a key pressed with modifiers, and what it does.
struct KeyBinding: Equatable, Sendable {
    /// The modifiers held down, all four for the hyper key.
    let modifiers: Set<Modifier>
    /// The key pressed.
    let key: Key
    /// What it does.
    let action: KeyAction
}
