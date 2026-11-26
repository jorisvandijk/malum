/// The catalogs of git and ssh, whose settings go into their config files.
extension AppCatalogs {
    // MARK: - git

    /// The table git's config is written from, a table per section.
    static let gitSections = "settings"

    /// The key `key` in the section `section` of git's config.
    private static func git(_ section: String, _ key: String) -> CatalogSetting.Target {
        .file([gitSections, section, key])
    }

    /// The section that makes git reach GitHub over ssh, and the address it stands in for.
    private static let gitHubOverSSH = (section: "url.git@github.com:", replaces: "https://github.com/")

    /// `apps/git.toml`.
    static let git = Catalog(
        file: Paths.appFile(named: "git"),
        tables: [
            CatalogTable(
                name: "user", about: "Who your commits are by.",
                settings: [
                    CatalogSetting("name", "Your name.", .text(.plain), [git("user", "name")]),
                    CatalogSetting("email", "Your email address.", .text(.plain), [git("user", "email")]),
                ]),
            CatalogTable(
                name: "branches", about: "The branches of new repositories.",
                settings: [
                    CatalogSetting(
                        "default", "The name of the first branch of a new repository, such as \"main\".",
                        .text(.plain), [git("init", "defaultBranch")])
                ]),
            CatalogTable(
                name: "hooks", about: "The hooks every repository runs.",
                settings: [
                    CatalogSetting(
                        "folder", "The folder git takes hooks from, instead of each repository's own.", .path(),
                        [git("core", "hooksPath")])
                ]),
            CatalogTable(
                name: "push", about: "What git push does.",
                settings: [
                    CatalogSetting(
                        "auto_set_upstream",
                        "Whether pushing a new branch makes it on the remote and tracks it, without "
                            + "--set-upstream.", .flag, [git("push", "autoSetupRemote")])
                ]),
            CatalogTable(
                name: "github", about: "How git reaches GitHub.",
                settings: [
                    CatalogSetting(
                        "use_ssh", "Whether git reaches GitHub over ssh, even for an https:// address.",
                        .combinedFlag(on: [.set(.string(gitHubOverSSH.replaces))], off: [.remove]),
                        [git(gitHubOverSSH.section, "insteadOf")])
                ]),
        ])

    // MARK: - ssh

    /// The table ssh's config is written from, a table per `Host` section.
    static let sshHosts = "hosts"
    /// The `Host` section that holds what's true of every host.
    private static let sshEveryHost = "*"

    /// `apps/ssh.toml`. The agent's settings hold for every host.
    static let ssh = Catalog(
        file: Paths.appFile(named: "ssh"),
        tables: [
            CatalogTable(
                name: "agent", about: "What ssh does with the agent that holds your keys.",
                settings: [
                    CatalogSetting(
                        "add_keys", "Whether ssh gives a key it uses to the agent, so you unlock it once.", .flag,
                        [.file([sshHosts, sshEveryHost, "AddKeysToAgent"])]),
                    CatalogSetting(
                        "use_keychain", "Whether ssh keeps the passphrases of keys in the macOS keychain.", .flag,
                        [.file([sshHosts, sshEveryHost, "UseKeychain"])]),
                ]),
            CatalogTable(
                name: "keys", about: "Your keys, and the hosts each one is for.",
                entries: CatalogEntries(
                    keys: "a name for the key, such as github",
                    settings: [
                        CatalogSetting(
                            "file", "The key's private file, such as \"$HOME/.ssh/id_ed25519\".", .path(),
                            [.file([sshHosts, CatalogEntries.item("hosts"), "IdentityFile"])]),
                        CatalogSetting("hosts", "The hosts ssh uses the key for.", .list(.hosts), []),
                    ],
                    each: "hosts")),
        ])
}
