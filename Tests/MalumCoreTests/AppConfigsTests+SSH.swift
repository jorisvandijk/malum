import Testing

@testable import MalumCore

/// ssh's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    @Test func sshWritesHostSectionsWithPatternsLast() throws {
        let (files, problems) = try read(
            """
            [hosts."*"]
            ServerAliveInterval = 60

            [hosts."github.com"]
            IdentityFile = "~/.ssh/id_ed25519"
            UseKeychain = true

            [hosts.homelab]
            HostName = "192.168.1.5"
            User = "root"
            """, app: "ssh")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".ssh/config",
                    Self.header(of: "ssh") + "Host github.com\n  IdentityFile ~/.ssh/id_ed25519\n  UseKeychain yes\n\n"
                        + "Host homelab\n  HostName 192.168.1.5\n  User root\n\n"
                        + "Host *\n  ServerAliveInterval 60\n")
            ])
    }

    @Test func sshHostThatIsntATableIsAProblem() throws {
        let (files, problems) = try read("[hosts]\n\"github.com\" = \"yes\"\n", app: "ssh")
        #expect(files.isEmpty)
        #expect(problems.count == 1)
    }
}
