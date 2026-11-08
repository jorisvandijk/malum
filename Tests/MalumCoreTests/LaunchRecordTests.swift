import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LaunchRecordTests {
    let paths = Paths(home: "/Users/test")
    var file: String { "\(paths.stateDirectory)/launches" }

    func record(_ files: FakeFileSystem) -> LaunchRecord {
        LaunchRecord(state: StateFolder(files: files, locks: FakeFileLocks(), paths: paths))
    }

    @Test func firstStartIsWrittenDown() throws {
        let files = FakeFileSystem()
        #expect(try !record(files).record(at: 1000))
        #expect(files.text(at: file) == "1000\n")
    }

    @Test func thirdStartWithinTwoMinutesIsACrashLoop() throws {
        let files = FakeFileSystem()
        #expect(try !record(files).record(at: 1000))
        #expect(try !record(files).record(at: 1010))
        #expect(try record(files).record(at: 1119))
    }

    @Test func startsOlderThanTwoMinutesAreDropped() throws {
        let files = FakeFileSystem(texts: [file: "1000\n1010\n"])
        #expect(try !record(files).record(at: 1120))
        #expect(files.text(at: file) == "1010\n1120\n")
    }

    @Test func startsFromTheFutureAreDropped() throws {
        let files = FakeFileSystem(texts: [file: "5000\n5010\n"])
        #expect(try !record(files).record(at: 1000))
        #expect(files.text(at: file) == "1000\n")
    }

    @Test func clearForgetsEveryStart() throws {
        let files = FakeFileSystem(texts: [file: "1000\n1010\n"])
        try record(files).clear()
        #expect(try !record(files).record(at: 1020))
    }
}
