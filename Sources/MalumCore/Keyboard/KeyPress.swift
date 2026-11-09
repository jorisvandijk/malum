/// One key going down or up, as the event tap sees it.
public struct KeyPress: Equatable, Sendable {
    /// The virtual key code, as in `Key.keyCode`. Keys outside the table have codes too.
    let keyCode: UInt16
    /// Whether the key went down rather than up.
    let isDown: Bool
    /// Whether it's a key-down macOS repeats while the key is held.
    let isRepeat: Bool
    /// The modifiers held on the keyboard as it happened.
    let modifiers: Set<Modifier>

    /// The key `keyCode` going down, or up when `isDown` is false, with `modifiers` held.
    public init(keyCode: UInt16, isDown: Bool, isRepeat: Bool, modifiers: Set<Modifier>) {
        self.keyCode = keyCode
        self.isDown = isDown
        self.isRepeat = isRepeat
        self.modifiers = modifiers
    }
}
