/// What the Samba module works through.
@MainActor
public struct SambaSystem {
    /// The mounts and the network.
    let shares: any SambaShares
    /// Says when the network changes.
    let network: any NetworkWatch
    /// Runs `umount`.
    let runner: any CommandRunner
    /// The disk, to see whether a share's folder in `/Volumes` is taken.
    let files: any FileSystem
    /// Where each server's password is kept.
    let passwords: (SambaServer) -> any TokenStore

    /// Gathers the parts the Samba module needs.
    public init(
        shares: any SambaShares, network: any NetworkWatch, runner: any CommandRunner, files: any FileSystem,
        passwords: @escaping (SambaServer) -> any TokenStore
    ) {
        self.shares = shares
        self.network = network
        self.runner = runner
        self.files = files
        self.passwords = passwords
    }
}
