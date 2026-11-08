import Foundation

/// `malum token`: keeps the GitHub token that lets Malum see its own repository while it's private.
public struct TokenCommand: Sendable {
    /// Where the token is kept.
    private let store: any TokenStore
    /// GitHub, to check a token before it's kept.
    private let github: any GitHub

    /// Creates the command, which keeps the token in `store` once `github` accepts it.
    public init(store: any TokenStore, github: any GitHub) {
        self.store = store
        self.github = github
    }

    /// Stores `entered`, trimmed, once GitHub says it can read Malum's repository, replacing the token before.
    /// Nothing is stored when it's empty or GitHub refuses it.
    public func save(_ entered: String?) async -> Message {
        let token = (entered ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return .noTokenEntered }
        do {
            try await github.check(token, canRead: Project.repository)
            try store.save(token)
        } catch {
            return .failed(.saveToken, error)
        }
        return .tokenSaved
    }

    /// Removes the stored token.
    public func remove() -> Message {
        do {
            guard try store.remove() else { return .noTokenStored }
        } catch {
            return .failed(.removeToken, error)
        }
        return .tokenRemoved
    }

    /// Whether a token is stored, as `malum status` shows it.
    public func status() -> Message {
        do {
            return .tokenStatus(stored: try store.isStored())
        } catch {
            return .tokenUnreadable(error)
        }
    }
}
