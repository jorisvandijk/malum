/// Where Malum keeps its GitHub token, behind a protocol so tests never touch the keychain.
public protocol TokenStore: Sendable {
    /// The stored token, or nil when there's none.
    func token() throws(TokenStoreError) -> String?
    /// Whether a token is stored, without reading it, so nothing asks for the keychain's permission.
    func isStored() throws(TokenStoreError) -> Bool
    /// Stores `token`, replacing the one before.
    func save(_ token: String) throws(TokenStoreError)
    /// Removes the token. Says whether there was one.
    func remove() throws(TokenStoreError) -> Bool
}
