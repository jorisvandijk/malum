/// Which way a split key moves a border.
enum SplitMove: Sendable {
    /// The border between the left window and the rest goes left.
    case left
    /// The border between the left window and the rest goes right.
    case right
    /// The focused window in the right column gets taller.
    case taller
    /// The focused window in the right column gets shorter.
    case shorter
}
