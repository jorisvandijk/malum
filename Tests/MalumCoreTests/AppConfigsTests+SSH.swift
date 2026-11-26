import Testing

@testable import MalumCore

/// ssh's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    @Test func sshsOldHostTablesAreUnknown() throws {
        let (files, problems) = try read("[hosts.\"github.com\"]\nIdentityFile = \"~/.ssh/id_ed25519\"\n", app: "ssh")
        #expect(files.isEmpty)
        #expect(problems == [Message(.warn, "unknown table hosts")])
    }

    @Test func sshWritesEachKeysHostsAndTheAgentForEveryHostLast() throws {
        let (files, problems) = try read(
            """
            [agent]
            add_keys = true
            use_keychain = true

            [keys.github]
            file = "$HOME/.ssh/id_ed25519"
            hosts = ["github.com", "gist.github.com"]

            [keys.homelab]
            file = "$HOME/.ssh/homelab"
            hosts = ["192.168.1.5"]
            """, app: "ssh")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".ssh/config",
                    Self.header(of: "ssh") + "Host 192.168.1.5\n  IdentityFile /Users/test/.ssh/homelab\n\n"
                        + "Host gist.github.com\n  IdentityFile /Users/test/.ssh/id_ed25519\n\n"
                        + "Host github.com\n  IdentityFile /Users/test/.ssh/id_ed25519\n\n"
                        + "Host *\n  AddKeysToAgent yes\n  UseKeychain yes\n")
            ])
    }

    @Test func sshKeysThatLackSettingsOrShareAHostAreProblems() throws {
        let (files, problems) = try read(
            """
            [keys.spaced]
            hosts = ["git hub"]

            [keys.plain]
            file = "~/.ssh/plain"
            hosts = []
            color = "red"
            """, app: "ssh")
        #expect(files.isEmpty)
        #expect(
            problems == [
                Message(.warn, "unknown setting keys.plain.color"),
                Message(
                    .error, "keys.plain.file should be a path, starting with $HOME/ in your home folder or / outside it"
                ),
                Message(
                    .error,
                    MessageText(
                        "keys.plain.hosts should be a list of at least one host name or pattern, such as \"github.com\" "
                            + "or \"*.example.com\"")),
                Message(.error, "keys.spaced needs file"),
                Message(
                    .error,
                    MessageText(
                        "keys.spaced.hosts should be a list of at least one host name or pattern, such as \"github.com\" "
                            + "or \"*.example.com\"")),
            ])
    }

    @Test func sshKeysThatShareAHostAreAProblem() throws {
        let (files, problems) = try read(
            """
            [keys.first]
            file = "$HOME/.ssh/first"
            hosts = ["github.com"]

            [keys.second]
            file = "$HOME/.ssh/second"
            hosts = ["github.com"]
            """, app: "ssh")
        #expect(
            files == [
                AppFile(
                    ".ssh/config", Self.header(of: "ssh") + "Host github.com\n  IdentityFile /Users/test/.ssh/first\n")
            ])
        #expect(
            problems == [
                Message(.error, "keys.second.file sets the same setting as keys.first.file, to something else")
            ])
    }
}
