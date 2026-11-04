import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct CommandFilesTests {
    private let hash = "3F2A1B0C9D8E7F6A5B4C3D2E1F0A9B8C7D6E5F40"

    @Test func brewListsOneKindOfPackage() {
        #expect(Brew.installed(.cask) == Command("/opt/homebrew/bin/brew", ["list", "--cask", "-1"]))
    }

    @Test func brewInstallsWithALongTimeout() {
        #expect(
            Brew.install("ripgrep", kind: .formula)
                == Command("/opt/homebrew/bin/brew", ["install", "--formula", "ripgrep"], timeoutSeconds: 1800))
    }

    @Test func masInstallsAsRootOnTheTerminal() {
        #expect(
            Mas.install(497_799_835)
                == Command(
                    "/usr/bin/sudo", ["-n", "/opt/homebrew/bin/mas", "get", "497799835"], timeoutSeconds: 7200,
                    onTerminal: true))
    }

    @Test func dittoUnzipsIntoAFolder() {
        #expect(
            Ditto.unzip("/tmp/a.zip", into: "/tmp/out")
                == Command("/usr/bin/ditto", ["-x", "-k", "/tmp/a.zip", "/tmp/out"], timeoutSeconds: 300))
    }

    @Test func tarUnpacksIntoAFolder() {
        #expect(
            Tar.unpack("/tmp/a.tar.gz", into: "/tmp/out")
                == Command("/usr/bin/tar", ["-x", "-f", "/tmp/a.tar.gz", "-C", "/tmp/out"], timeoutSeconds: 300))
    }

    @Test func masListGivesTheIds() {
        let output = "497799835  Xcode  (26.0)\n 937984704  Amphetamine  (5.3.2)\nNo installed apps found\n"
        #expect(Mas.ids(in: output) == [497_799_835, 937_984_704])
    }

    @Test func sudoAsksOnTheTerminal() {
        #expect(Sudo.authorize.onTerminal)
        #expect(Sudo.authorize.arguments.first == "-v")
        #expect(Sudo.refresh == Command("/usr/bin/sudo", ["-n", "-v"], onTerminal: true))
    }

    @Test func codesignSignsWithoutTimestamp() {
        #expect(
            Codesign.sign("/A.app", identity: hash)
                == Command(
                    "/usr/bin/codesign", ["--force", "--sign", hash, "--timestamp=none", "/A.app"], timeoutSeconds: 300)
        )
    }

    @Test func codesignVerifiesAgainstTheCertificate() {
        #expect(
            Codesign.verify("/A.app", identity: hash)
                == Command(
                    "/usr/bin/codesign",
                    ["--verify", "--strict", "--test-requirement", "=certificate leaf = H\"\(hash)\"", "/A.app"]))
    }

    @Test func securityImportLetsCodesignUseTheKey() {
        #expect(
            Security.importIdentity("/t/id.p12", password: "pw", keychain: "/k")
                == Command(
                    "/usr/bin/security",
                    ["import", "/t/id.p12", "-k", "/k", "-f", "pkcs12", "-P", "pw", "-T", "/usr/bin/codesign"]))
    }

    @Test func identityIsFoundByName() {
        let output = """
            Policy: Code Signing
              Matching identities
              1) 1111111111111111111111111111111111111111 "Other"
              2) \(hash) "Malum code signing" (CSSMERR_TP_NOT_TRUSTED)
                 2 identities found
            """
        #expect(Security.identity(named: "Malum code signing", in: output) == hash)
        #expect(Security.identity(named: "Hopper", in: output) == nil)
    }

    @Test func opensslBundlesWithKeychainCiphers() {
        let command = OpenSSL.bundle(key: "/k", certificate: "/c", name: "N", password: "pw", output: "/o")
        #expect(command.executable == "/usr/bin/openssl")
        #expect(command.arguments.contains("PBE-SHA1-3DES"))
        #expect(command.arguments.last == "pass:pw")
    }

    @Test func launchctlNamesTheUsersSession() {
        let service = Launchctl.service("com.jorisvandijk.malum", userID: 501)
        #expect(service == "gui/501/com.jorisvandijk.malum")
        #expect(Launchctl.describe(service) == Command("/bin/launchctl", ["print", service]))
        #expect(Launchctl.restart(service) == Command("/bin/launchctl", ["kickstart", "-k", service]))
        #expect(
            Launchctl.load("/a.plist", into: "gui/501")
                == Command("/bin/launchctl", ["bootstrap", "gui/501", "/a.plist"]))
    }
}
