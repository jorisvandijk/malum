/// Where Malum keeps a secret, such as the GitHub token, behind a protocol so tests never touch the
/// keychain.
public protocol TokenStore: Sendable {
    /// The stored token, or nil when there's none.
    func token() async throws(TokenStoreError) -> String?
    /// Whether a token is stored, without reading it.
    func isStored() async throws(TokenStoreError) -> Bool
    /// Stores `token`, replacing the one before.
    func save(_ token: String) async throws(TokenStoreError)
    /// Removes the token. Says whether there was one.
    func remove() async throws(TokenStoreError) -> Bool
}
