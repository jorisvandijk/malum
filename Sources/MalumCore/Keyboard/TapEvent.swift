/// What the event tap hands to `KeyTap`.
public enum TapEvent: Equatable, Sendable {
    /// A key went down or up.
    case key(KeyPress)
    /// A modifier went down or up, leaving these held.
    case modifiersChanged(Set<Modifier>)
    /// macOS switched the tap off, so it may have missed key-ups.
    case switchedOff
}
