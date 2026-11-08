/// The words at the top of each file Malum writes from dots, which say where it comes from.
enum FileHeader {
    /// The header of an app config file written from `source`, the app's file in `apps/`.
    static func appFile(from source: String) -> String {
        "\(writtenBy(source)). Changes made here are overwritten."
    }

    /// The comment line in `/etc/pam.d/sudo_local` when it lets sudo take Touch ID.
    static var touchID: String {
        "# \(writtenBy(Paths.macOSTOMLName)) ([sudo] touch_id)."
    }

    /// The comment lines in `/etc/hosts` when `macos.toml` sets it.
    static var hosts: String {
        """
        # \(writtenBy(Paths.macOSTOMLName)). Changes made here are
        # overwritten on the next run: change [hosts] in \(Paths.macOSTOMLName) instead.
        """
    }

    /// Says the file was written by Malum from `source` in dots.
    private static func writtenBy(_ source: String) -> String {
        "Written by \(Project.name) from \(source) in dots"
    }
}
