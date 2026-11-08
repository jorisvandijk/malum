import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct PathsTests {
    let paths = Paths(home: "/Users/test")

    @Test func configFileIsUnderDotConfig() {
        #expect(paths.configFile == "/Users/test/.config/malum/config")
    }

    @Test func commandLinkIsInLocalBin() {
        #expect(paths.commandLink == "/Users/test/.local/bin/malum")
    }

    @Test func stateDirectoryIsNamedAfterBundleID() {
        #expect(paths.stateDirectory == "/Users/test/Library/Application Support/\(Project.bundleID)")
    }

    @Test func installedExecutableIsInHomeApplications() {
        #expect(paths.installedExecutable == "/Users/test/Applications/Malum.app/Contents/MacOS/Malum")
    }

    @Test func appFileIsInAppsFolder() {
        #expect(Paths.appFile(named: "git") == "apps/git.toml")
    }

    @Test func installedBundleAndKeychainAreInHome() {
        #expect(paths.installedBundle == "/Users/test/Applications/Malum.app")
        #expect(paths.loginKeychain == "/Users/test/Library/Keychains/login.keychain-db")
    }

    @Test func loginAgentIsNamedAfterBundleID() {
        #expect(paths.loginAgent == "/Users/test/Library/LaunchAgents/\(Project.bundleID).plist")
    }

    @Test func configTOMLIsAtTheTopOfDots() {
        #expect(paths.configTOML(in: "/Users/test/Git/dots") == "/Users/test/Git/dots/malum.toml")
    }

    @Test func moduleTOMLIsNamedAfterTheModuleAtTheTopOfDots() {
        #expect(paths.moduleTOML("keyboard", in: "/Users/test/Git/dots") == "/Users/test/Git/dots/keyboard.toml")
    }

    @Test func tildeExpandsToHome() {
        #expect(paths.resolve("~/git/dots", relativeTo: "/tmp") == "/Users/test/git/dots")
        #expect(paths.resolve("~", relativeTo: "/tmp") == "/Users/test")
    }

    @Test func relativePathIsReadFromBase() {
        #expect(paths.resolve("../dots", relativeTo: "/Users/test/git/malum") == "/Users/test/git/dots")
    }

    @Test func absolutePathIsCleaned() {
        #expect(paths.resolve("/Users/test/git/./dots/", relativeTo: "/tmp") == "/Users/test/git/dots")
    }

    @Test func folderIsThePathWithoutItsLastPart() {
        #expect(Paths.folder(of: "/Users/test/.config/git/config") == "/Users/test/.config/git")
        #expect(Paths.folder(of: "/config") == "/")
    }
}
