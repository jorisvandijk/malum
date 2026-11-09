/// Whether secure input is on. While it is, as in a password field, macOS hands no key to the event tap.
public enum SecureInput: Equatable, Sendable {
    /// Keys reach the tap.
    case off
    /// `app` turned secure input on; nil when macOS doesn't say which.
    case on(app: String?)
}
