/// One key going down or up, as the event tap sees it.
struct KeyPress: Equatable, Sendable {
    /// The virtual key code, as in `Key.keyCode`. Keys outside the table have codes too.
    let keyCode: UInt16
    /// Whether the key went down rather than up.
    let isDown: Bool
    /// Whether it's a key-down macOS repeats while the key is held.
    let isRepeat: Bool
    /// The modifiers held on the keyboard as it happened.
    let modifiers: Set<Modifier>
}
