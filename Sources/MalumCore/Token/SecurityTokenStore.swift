/// A secret, such as the GitHub token or a Samba password, as a generic password in the login
/// keychain, kept and read through `security`.
///
/// The keychain lets the app that made an item read it without asking. Malum's own code changes
/// with every update, so an item Malum made asked for the login password after each one. `security`
/// stays the same, so an item it makes never asks.
public struct SecurityTokenStore: Sendable {
    /// Runs `security`.
    private let runner: any CommandRunner
    /// The item's service.
    private let service: String
    /// The item's account.
    private let account: String

    /// Creates access to the item with `service` and `account`, by default the GitHub token's.
    public init(runner: any CommandRunner, service: String = Project.tokenService, account: String = Project.command) {
        self.runner = runner
        self.service = service
        self.account = account
    }

    /// Runs `command`, which answers about the item. Says whether the item is there, and throws
    /// when `security` failed for another reason.
    private func found(_ command: Command) async throws(TokenStoreError) -> CommandResult? {
        let result = await runner.run(command)
        guard result.status != Security.notFoundStatus else { return nil }
        guard result.succeeded else { throw .keychain(reason: result.reason) }
        return result
    }
}

// MARK: - TokenStore

extension SecurityTokenStore: TokenStore {
    /// Reads the item's password, without the line break `security` ends it with.
    public func token() async throws(TokenStoreError) -> String? {
        guard let result = try await found(Security.findPassword(service: service, account: account)) else {
            return nil
        }
        guard result.output.hasSuffix("\n") else { return result.output }
        return String(result.output.dropLast())
    }

    /// Looks the item up without its password.
    public func isStored() async throws(TokenStoreError) -> Bool {
        try await found(Security.findItem(service: service, account: account)) != nil
    }

    /// Adds the item or replaces its password, then reads it back, since `security` reading its
    /// commands from stdin doesn't always say when one failed.
    public func save(_ token: String) async throws(TokenStoreError) {
        let result = await runner.run(Security.savePassword(token, service: service, account: account))
        guard result.succeeded else { throw .keychain(reason: result.reason) }
        guard try await self.token() == token else { throw .unsaved }
    }

    /// Deletes the item.
    public func remove() async throws(TokenStoreError) -> Bool {
        try await found(Security.deletePassword(service: service, account: account)) != nil
    }
}
