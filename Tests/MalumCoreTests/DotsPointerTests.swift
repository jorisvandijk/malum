import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct DotsPointerTests {
    let paths = Paths(home: "/Users/joris")

    @Test func missingRecordReadsAsNil() throws {
        #expect(try DotsPointer(files: FakeFileSystem(), paths: paths).read() == nil)
    }

    @Test func recordIsTrimmed() throws {
        let files = FakeFileSystem(texts: [paths.configFile: "/Users/joris/git/dots\n"])
        #expect(try DotsPointer(files: files, paths: paths).read() == "/Users/joris/git/dots")
    }

    @Test func emptyRecordReadsAsNil() throws {
        let files = FakeFileSystem(texts: [paths.configFile: "\n"])
        #expect(try DotsPointer(files: files, paths: paths).read() == nil)
    }

    @Test func writeCreatesTheFolderAndTheRecord() throws {
        let files = FakeFileSystem()
        try DotsPointer(files: files, paths: paths).write("/Users/joris/git/dots")
        #expect(files.item(at: paths.configDirectory) == .directory)
        #expect(files.text(at: paths.configFile) == "/Users/joris/git/dots\n")
    }
}
