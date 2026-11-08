/// One key that types as another, from `[remap]` in `keyboard.toml`.
struct KeyRemap: Equatable, Sendable {
    /// The key pressed.
    let from: Key
    /// The key it types as.
    let to: Key
}
