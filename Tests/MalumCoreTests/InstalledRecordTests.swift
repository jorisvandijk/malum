import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct InstalledRecordTests {
    let files = FakeFileSystem()
    var state: StateFolder { StateFolder(files: files, locks: FakeFileLocks(), paths: Paths(home: "/Users/joris")) }
    var path: String { state.path(of: "installed.json") }

    @Test func changeOfAnUnreadableRecordLeavesItAsItIs() throws {
        try files.write("not json", to: path)
        #expect(throws: RecordError.unreadable(path: path)) {
            try InstalledRecord.change(in: state) { $0.formulae = ["bat"] }
        }
        #expect(files.text(at: path) == "not json")
    }

    @Test func changeWritesTheRecord() throws {
        try InstalledRecord.change(in: state) { $0.formulae = ["bat"] }
        #expect(try InstalledRecord.read(from: state).formulae == ["bat"])
    }
}
