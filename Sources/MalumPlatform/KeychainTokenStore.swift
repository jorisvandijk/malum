import Foundation
import MalumCore
import Security

/// A secret, such as the GitHub token or a Samba password, as a generic password in the login
/// keychain, through the Security framework, so it never shows up on a command line.
public struct KeychainTokenStore {
    /// The item's service.
    private let service: String
    /// The item's account.
    private let account: String

    /// Creates access to the item with `service` and `account`, by default the GitHub token's.
    public init(service: String = Project.tokenService, account: String = Project.command) {
        self.service = service
        self.account = account
    }

    /// What finds the item: a generic password by service and account.
    private var item: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
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
        var query = item
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let data = result as? Data, let token = String(bytes: data, encoding: .utf8)
        else { throw Self.error(status) }
        return token
    }

    /// Looks the item up without its data.
    public func isStored() throws(TokenStoreError) -> Bool {
        let status = SecItemCopyMatching(item as CFDictionary, nil)
        guard status != errSecItemNotFound else { return false }
        guard status == errSecSuccess else { throw Self.error(status) }
        return true
    }

    /// Changes the item's data, or adds the item when there's none.
    public func save(_ token: String) throws(TokenStoreError) {
        let data = Data(token.utf8)
        let updated = SecItemUpdate(item as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        guard updated == errSecItemNotFound else {
            guard updated == errSecSuccess else { throw Self.error(updated) }
            return
        }
        var item = item
        item[kSecValueData as String] = data
        let added = SecItemAdd(item as CFDictionary, nil)
        guard added == errSecSuccess else { throw Self.error(added) }
    }

    /// Deletes the item.
    public func remove() throws(TokenStoreError) -> Bool {
        let status = SecItemDelete(item as CFDictionary)
        guard status != errSecItemNotFound else { return false }
        guard status == errSecSuccess else { throw Self.error(status) }
        return true
    }
}
