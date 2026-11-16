import Foundation

/// A secret, such as the GitHub token or a Samba password, as a file only the user can read in
/// `~/.config/malum/secrets/<service>/<account>`.
///
/// A file needs no keychain, so no update of Malum or of macOS ever makes something ask for it.
public struct FileTokenStore: Sendable {
    /// The disk.
    private let files: any FileSystem
    /// Where the secrets folder is.
    private let paths: Paths
    /// The secret's kind, its folder's name.
    private let service: String
    /// Whose secret it is, its file's name.
    private let account: String

    /// Creates access to the secret of `account` for `service`, by default the GitHub token.
    public init(
        files: any FileSystem, paths: Paths, service: String = Project.tokenService, account: String = Project.command
    ) {
        self.files = files
        self.paths = paths
        self.service = service
        self.account = account
    }

    /// The secret's file.
    private var path: String { paths.secret(service: service, account: account) }
}

// MARK: - TokenStore

extension FileTokenStore: TokenStore {
    /// Reads the secret, or nil when its file isn't there.
    public func token() async throws(TokenStoreError) -> String? {
        do {
            return try files.text(ifFileAt: path)
        } catch {
            throw .file(error)
        }
    }

    /// Whether the secret's file is there.
    public func isStored() async throws(TokenStoreError) -> Bool {
        files.item(at: path) != nil
    }

    /// Writes the secret, readable only by the user, in folders only the user can open, replacing
    /// the one before.
    public func save(_ token: String) async throws(TokenStoreError) {
        do {
            try files.createPrivateDirectory(paths.secretsDirectory)
            try files.createPrivateDirectory(Paths.folder(of: path))
            try files.writePrivate(Data(token.utf8), to: path)
        } catch {
            throw .file(error)
        }
    }

    /// Removes the secret's file. Says whether there was one.
    public func remove() async throws(TokenStoreError) -> Bool {
        guard files.item(at: path) != nil else { return false }
        do {
            try files.remove(path)
        } catch {
            throw .file(error)
        }
        return true
    }
}
