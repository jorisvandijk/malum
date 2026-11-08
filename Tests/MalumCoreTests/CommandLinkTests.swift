import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct CommandLinkTests {
    let paths = Paths(home: "/Users/test")
    let executable = "/Users/test/Applications/Malum.app/Contents/MacOS/Malum"

    @Test func missingLinkIsCreated() throws {
        let files = FakeFileSystem()
        #expect(try CommandLink(files: files, paths: paths).point(to: executable) == .created)
        #expect(files.item(at: paths.binDirectory) == .directory)
        #expect(files.item(at: paths.commandLink) == .link(to: executable))
    }

    @Test func linkToMalumIsUnchanged() throws {
        let files = FakeFileSystem(items: [paths.commandLink: .link(to: executable)])
        #expect(try CommandLink(files: files, paths: paths).point(to: executable) == .unchanged)
    }

    @Test func linkElsewhereIsMoved() throws {
        let files = FakeFileSystem(items: [paths.commandLink: .link(to: "/Applications/Malum.app/Contents/MacOS/Malum")]
        )
        let change = try CommandLink(files: files, paths: paths).point(to: executable)
        #expect(change == .moved(from: "/Applications/Malum.app/Contents/MacOS/Malum"))
        #expect(files.item(at: paths.commandLink) == .link(to: executable))
    }

    @Test func fileInTheWayIsReported() {
        let files = FakeFileSystem(items: [paths.commandLink: .file])
        #expect(throws: SetupError.occupied(path: paths.commandLink)) {
            try CommandLink(files: files, paths: paths).point(to: executable)
        }
    }

    @Test func failedLinkIsReported() {
        let files = FakeFileSystem(failing: [paths.commandLink])
        #expect(throws: SetupError.file(.unlinkable(path: paths.commandLink, reason: "read-only"))) {
            try CommandLink(files: files, paths: paths).point(to: executable)
        }
    }

    @Test func firstStartCreatesMissingLink() throws {
        let files = FakeFileSystem()
        #expect(try CommandLink(files: files, paths: paths).createIfMissing(to: executable))
        #expect(files.item(at: paths.commandLink) == .link(to: executable))
    }

    @Test func firstStartLeavesExistingLinkAlone() throws {
        let files = FakeFileSystem(items: [paths.commandLink: .link(to: "/elsewhere")])
        #expect(try !CommandLink(files: files, paths: paths).createIfMissing(to: executable))
        #expect(files.item(at: paths.commandLink) == .link(to: "/elsewhere"))
    }

    @Test func firstStartLeavesFileAlone() throws {
        let files = FakeFileSystem(items: [paths.commandLink: .file])
        #expect(try !CommandLink(files: files, paths: paths).createIfMissing(to: executable))
    }
}
