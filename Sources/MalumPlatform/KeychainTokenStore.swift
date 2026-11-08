import Foundation
import MalumCore
import Security

/// The GitHub token as a generic password in the login keychain, through the Security framework,
/// so the token never shows up on a command line.
public struct KeychainTokenStore {
    /// Creates access to the token.
    public init() {}

    /// What finds the token's item: a generic password by service and account.
    private static var item: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Project.tokenService,
            kSecAttrAccount as String: Project.command,
        ]
    }

    /// The keychain's answer `status` as an error.
    private static func error(_ status: OSStatus) -> TokenStoreError {
        .keychain(status: status, reason: SecCopyErrorMessageString(status, nil) as String?)
    }
}

// MARK: - TokenStore

extension KeychainTokenStore: TokenStore {
    /// Reads the token's item.
    public func token() throws(TokenStoreError) -> String? {
        var query = Self.item
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw Self.error(status) }
        return String(decoding: data, as: UTF8.self)
    }

    /// Looks the item up without its data.
    public func isStored() throws(TokenStoreError) -> Bool {
        let status = SecItemCopyMatching(Self.item as CFDictionary, nil)
        guard status != errSecItemNotFound else { return false }
        guard status == errSecSuccess else { throw Self.error(status) }
        return true
    }

    /// Changes the item's data, or adds the item when there's none.
    public func save(_ token: String) throws(TokenStoreError) {
        let data = Data(token.utf8)
        let updated = SecItemUpdate(Self.item as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        guard updated == errSecItemNotFound else {
            guard updated == errSecSuccess else { throw Self.error(updated) }
            return
        }
        var item = Self.item
        item[kSecValueData as String] = data
        let added = SecItemAdd(item as CFDictionary, nil)
        guard added == errSecSuccess else { throw Self.error(added) }
    }

    /// Deletes the item.
    public func remove() throws(TokenStoreError) -> Bool {
        let status = SecItemDelete(Self.item as CFDictionary)
        guard status != errSecItemNotFound else { return false }
        guard status == errSecSuccess else { throw Self.error(status) }
        return true
    }
}
