import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LoginAgentTests {
    let paths = Paths(home: "/Users/test")
    let installed = "/Users/test/Applications/Malum.app/Contents/MacOS/Malum"

    @Test func missingAgentIsWritten() throws {
        let files = FakeFileSystem()
        #expect(try LoginAgent(files: files, paths: paths).update(executable: installed) == .written)
        #expect(files.item(at: paths.launchAgentsDirectory) == .directory)
        #expect(files.text(at: paths.loginAgent) == LoginAgent.plist(program: installed))
    }

    @Test func sameAgentIsLeftAlone() throws {
        let files = FakeFileSystem(texts: [paths.loginAgent: LoginAgent.plist(program: installed)])
        #expect(try LoginAgent(files: files, paths: paths).update(executable: installed) == .unchanged)
    }

    @Test func changedAgentIsWrittenAgain() throws {
        let files = FakeFileSystem(texts: [paths.loginAgent: "<plist/>"])
        #expect(try LoginAgent(files: files, paths: paths).update(executable: installed) == .written)
        #expect(files.text(at: paths.loginAgent) == LoginAgent.plist(program: installed))
    }

    @Test func installedAppSpelledDifferentlyWritesAgent() throws {
        let typed = "/Users/test/applications/Malum.app/Contents/MacOS/Malum"
        let files = FakeFileSystem(spellings: [typed: installed])
        #expect(try LoginAgent(files: files, paths: paths).update(executable: typed) == .written)
        #expect(files.text(at: paths.loginAgent) == LoginAgent.plist(program: installed))
    }

    @Test func buildFolderLeavesAgentAlone() throws {
        let files = FakeFileSystem()
        let built = "/Users/test/Git/malum/build/Malum.app/Contents/MacOS/Malum"
        #expect(try LoginAgent(files: files, paths: paths).update(executable: built) == .notInstalled)
        #expect(files.item(at: paths.loginAgent) == nil)
    }

    @Test func outsideAppBundleLeavesAgentAlone() throws {
        let files = FakeFileSystem()
        #expect(try LoginAgent(files: files, paths: paths).update(executable: nil) == .notInstalled)
        #expect(files.item(at: paths.loginAgent) == nil)
    }

    @Test func failedWriteIsReported() {
        let files = FakeFileSystem(failing: [paths.loginAgent])
        #expect(throws: FileSystemError.unwritable(path: paths.loginAgent, reason: "read-only")) {
            try LoginAgent(files: files, paths: paths).update(executable: installed)
        }
    }

    @Test func agentRestartsOnlyAfterACrash() {
        let plist = LoginAgent.plist(program: installed)
        #expect(plist.contains("<key>KeepAlive</key>\n    <dict>\n        <key>SuccessfulExit</key>\n        <false/>"))
        #expect(plist.contains("<key>RunAtLoad</key>\n    <true/>"))
    }

    @Test func agentStartsInstalledApp() {
        let plist = LoginAgent.plist(program: installed)
        #expect(plist.contains("<string>com.jorisvandijk.malum</string>"))
        #expect(plist.contains("<array>\n        <string>\(installed)</string>\n    </array>"))
    }

    @Test func programPathIsEscaped() {
        let plist = LoginAgent.plist(program: "/Users/a&b/<x>")
        #expect(plist.contains("<string>/Users/a&amp;b/&lt;x&gt;</string>"))
    }
}
