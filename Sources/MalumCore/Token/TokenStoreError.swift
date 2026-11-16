/// Why the token couldn't be read, stored or removed.
public enum TokenStoreError: Error, Equatable, Sendable {
    /// `security` failed, for `reason`.
    case keychain(reason: String)
    /// `security` ran, but the keychain doesn't hold what was saved.
    case unsaved
}
