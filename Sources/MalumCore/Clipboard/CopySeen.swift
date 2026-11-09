/// What the clipboard watch saw after something was copied.
public enum CopySeen: Equatable, Sendable {
    /// A copy to keep.
    case copied(Copy)
    /// A copy marked as one not to keep, such as a password, with the type that marks it.
    case skipped(String)
}
