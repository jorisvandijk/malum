import Synchronization

@testable import MalumCore

/// A token store held in memory, which fails every call with `failure` when it's set.
final class FakeTokenStore: TokenStore {
    /// The stored token.
    private let stored: Mutex<String?>
    /// What every call throws, or nil to work.
    private let failure: TokenStoreError?

    init(_ token: String? = nil, failure: TokenStoreError? = nil) {
        stored = Mutex(token)
        self.failure = failure
    }

    var current: String? { stored.withLock { $0 } }

    func token() throws(TokenStoreError) -> String? {
        if let failure { throw failure }
        return current
    }

    func isStored() throws(TokenStoreError) -> Bool {
        try token() != nil
    }

    func save(_ token: String) throws(TokenStoreError) {
        if let failure { throw failure }
        stored.withLock { $0 = token }
    }

    func remove() throws(TokenStoreError) -> Bool {
        if let failure { throw failure }
        return stored.withLock { old in
            defer { old = nil }
            return old != nil
        }
    }
}
