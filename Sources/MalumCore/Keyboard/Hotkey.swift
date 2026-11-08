/// A key pressed with modifiers held down, such as cmd+h.
struct Hotkey: Hashable, Sendable {
    /// The modifiers held down, all four for the hyper key.
    let modifiers: Set<Modifier>
    /// The key pressed.
    let key: Key
}
