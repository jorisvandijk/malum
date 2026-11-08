/// A file only root can change that `macos.toml` sets: `/etc/hosts` or Touch ID for sudo.
struct SystemFile: Equatable, Sendable {
    /// Where it is.
    let path: String
    /// What it holds when dots doesn't set it: macOS's own text, or nil when macOS has no such file.
    let original: String?

    /// The names this Mac looks up itself.
    static let hosts = SystemFile(
        path: "/etc/hosts",
        original: hostsHeader(
            """
            # localhost is used to configure the loopback interface
            # when the system is booting.  Do not change this entry.
            """))
    /// Sudo's own settings, which macOS keeps across updates.
    static let sudoLocal = SystemFile(path: "/etc/pam.d/sudo_local", original: nil)
    /// Every file `macos.toml` can set.
    static let all = [hosts, sudoLocal]

    /// What `/etc/pam.d/sudo_local` holds to let sudo take Touch ID.
    static let touchID = """
        # sudo_local: local config file which survives system update and is included for sudo
        # Written by \(Project.name) from \(Paths.macOSTOMLName) in dots ([sudo] touch_id).
        auth       sufficient     pam_tid.so

        """

    /// What `/etc/hosts` holds for `entries`, each a host name with its address: macOS's own
    /// lines, then one line for each entry.
    static func hosts(_ entries: [(key: String, value: String)]) -> String {
        let header = hostsHeader(
            """
            # Written by \(Project.name) from \(Paths.macOSTOMLName) in dots. Changes made here are
            # overwritten on the next run: change [hosts] in \(Paths.macOSTOMLName) instead.
            """)
        return entries.isEmpty ? header : header + "\n" + entries.map { "\($0.value)\t\($0.key)\n" }.joined()
    }

    /// macOS's hosts file with `comment` in its heading.
    private static func hostsHeader(_ comment: String) -> String {
        """
        ##
        # Host Database
        #
        \(comment)
        ##
        127.0.0.1\tlocalhost
        255.255.255.255\tbroadcasthost
        ::1             localhost

        """
    }
}
