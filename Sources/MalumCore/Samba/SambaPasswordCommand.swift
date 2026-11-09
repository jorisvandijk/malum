/// `malum samba password <server>`: keeps the password of a server in `samba.toml` in the login
/// keychain, so it never shows up in dots or on a command line.
@MainActor
public struct SambaPasswordCommand {
    /// The disk, to read dots.
    private let files: any FileSystem
    /// Where dots is recorded.
    private let paths: Paths
    /// Where a server's password is kept.
    private let store: (SambaServer) -> any TokenStore

    /// Creates the command, which keeps each server's password in the store `store` gives for it.
    public init(files: any FileSystem, paths: Paths, store: @escaping (SambaServer) -> any TokenStore) {
        self.files = files
        self.paths = paths
        self.store = store
    }

    /// The server called `name` in dots, or nil after telling `report` why there's none.
    public func server(named name: String, report: (Message) -> Void) -> SambaServer? {
        let reloader = ConfigReloader(files: files, paths: paths, schemas: Modules.schemas)
        let problems = reloader.reload(force: true)?.problems ?? []
        guard let table = reloader.settings[SambaConfig.module] else {
            problems.map(\.message).forEach(report)
            report(.noSambaSettings)
            return nil
        }
        let servers = SambaConfig.read(table) { _, _ in }.servers
        guard !servers.isEmpty else {
            report(.noSambaSettings)
            return nil
        }
        guard let server = servers.first(where: { $0.name == name }) else {
            report(.noSambaServer(name, known: servers.map(\.name)))
            return nil
        }
        return server
    }

    /// Stores `entered` as `server`'s password, replacing the one before. Nothing is stored when
    /// it's empty.
    public func save(_ entered: String?, for server: SambaServer) -> Message {
        guard let password = entered, !password.isEmpty else { return .noPasswordEntered }
        do {
            try store(server).save(password)
        } catch {
            return .failed(.savePassword(server.account), error)
        }
        return .passwordSaved(server.account)
    }

}
