/// Why the keyboard module couldn't do its work.
public enum KeyboardError: Error, Equatable, Sendable {
    /// macOS refused the event tap, so no key can be caught.
    case tapRefused
    /// macOS switched the event tap off, as it does when Accessibility is taken away, so it's started again.
    case tapSwitchedOff
}
