/// The Mac's Samba mounts and the network the module works through.
public protocol SambaShares: Sendable {
    /// The Samba shares mounted now.
    func mounts() -> [SambaMount]
    /// Whether `host` answers on the Samba port within a few seconds.
    func isReachable(_ host: String) async -> Bool
    /// Mounts `share` from `server` under `/Volumes` with `password`, without any dialog.
    func mount(_ share: String, from server: SambaServer, password: String) async throws(SambaMountError)
}
