import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct DotsPointerTests {
    let paths = Paths(home: "/Users/test")

    @Test func missingRecordReadsAsNil() throws {
        #expect(try DotsPointer(files: FakeFileSystem(), paths: paths).read() == nil)
    }

    @Test func recordIsTrimmed() throws {
        let files = FakeFileSystem(texts: [paths.configFile: "/Users/test/git/dots\n"])
        #expect(try DotsPointer(files: files, paths: paths).read() == "/Users/test/git/dots")
    }

    @Test func emptyRecordReadsAsNil() throws {
        let files = FakeFileSystem(texts: [paths.configFile: "\n"])
        #expect(try DotsPointer(files: files, paths: paths).read() == nil)
    }

    @Test func writeCreatesTheFolderAndTheRecord() throws {
        let files = FakeFileSystem()
        try DotsPointer(files: files, paths: paths).write("/Users/test/git/dots")
        #expect(files.item(at: paths.configDirectory) == .directory)
        #expect(files.text(at: paths.configFile) == "/Users/test/git/dots\n")
    }
}
