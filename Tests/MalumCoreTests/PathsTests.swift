import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct PathsTests {
    let paths = Paths(home: "/Users/joris")

    @Test func configFileIsUnderDotConfig() {
        #expect(paths.configFile == "/Users/joris/.config/malum/config")
    }

    @Test func commandLinkIsInLocalBin() {
        #expect(paths.commandLink == "/Users/joris/.local/bin/malum")
    }

    @Test func stateDirectoryIsNamedAfterBundleID() {
        #expect(paths.stateDirectory == "/Users/joris/Library/Application Support/com.jorisvandijk.malum")
    }

    @Test func tildeExpandsToHome() {
        #expect(paths.resolve("~/git/dots", relativeTo: "/tmp") == "/Users/joris/git/dots")
        #expect(paths.resolve("~", relativeTo: "/tmp") == "/Users/joris")
    }

    @Test func relativePathIsReadFromBase() {
        #expect(paths.resolve("../dots", relativeTo: "/Users/joris/git/malum") == "/Users/joris/git/dots")
    }

    @Test func absolutePathIsCleaned() {
        #expect(paths.resolve("/Users/joris/git/./dots/", relativeTo: "/tmp") == "/Users/joris/git/dots")
    }
}
