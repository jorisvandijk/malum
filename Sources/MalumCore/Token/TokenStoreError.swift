/// Why the token couldn't be read, stored or removed.
public enum TokenStoreError: Error, Equatable, Sendable {
    /// The keychain answered with an error `status`, which `reason` explains when the keychain has words for it.
    case keychain(status: Int32, reason: String?)
}
