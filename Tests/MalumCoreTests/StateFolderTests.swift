import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct StateFolderTests {
    let paths = Paths(home: "/Users/joris")
    var folder: String { paths.stateDirectory }

    @Test func writeCreatesFolderAndTakesLock() throws {
        let files = FakeFileSystem()
        let locks = FakeFileLocks()
        try StateFolder(files: files, locks: locks, paths: paths).write("on\n", to: "safe")
        #expect(files.item(at: folder) == .directory)
        #expect(files.text(at: "\(folder)/safe") == "on\n")
        #expect(locks.runs == ["\(folder)/state.lock"])
    }

    @Test func writeFailsWhenLockFails() {
        let files = FakeFileSystem()
        let locks = FakeFileLocks(failing: ["\(folder)/state.lock"])
        #expect(throws: StateError.unlockable(path: "\(folder)/state.lock", reason: "permission denied")) {
            try StateFolder(files: files, locks: locks, paths: paths).write("on\n", to: "safe")
        }
        #expect(files.text(at: "\(folder)/safe") == nil)
    }

    @Test func writeFailureIsReported() {
        let files = FakeFileSystem(failing: ["\(folder)/safe"])
        #expect(throws: StateError.file(.unwritable(path: "\(folder)/safe", reason: "read-only"))) {
            try StateFolder(files: files, locks: FakeFileLocks(), paths: paths).write("on\n", to: "safe")
        }
    }

    @Test func readMissingFileIsNil() throws {
        #expect(try StateFolder(files: FakeFileSystem(), locks: FakeFileLocks(), paths: paths).read("safe") == nil)
    }

    @Test func readReturnsText() throws {
        let files = FakeFileSystem(texts: ["\(folder)/safe": "on\n"])
        #expect(try StateFolder(files: files, locks: FakeFileLocks(), paths: paths).read("safe") == "on\n")
    }

    @Test func lockErrorNamesThePath() {
        let error = StateError.unlockable(path: "/tmp/state.lock", reason: "permission denied")
        #expect(error.description == "couldn't lock /tmp/state.lock: permission denied")
    }

    @Test func updateChangesTextUnderTheLock() throws {
        let files = FakeFileSystem(texts: ["\(folder)/disabled": "samba\n"])
        let locks = FakeFileLocks()
        try StateFolder(files: files, locks: locks, paths: paths).update("disabled") { ($0 ?? "") + "launcher\n" }
        #expect(files.text(at: "\(folder)/disabled") == "samba\nlauncher\n")
        #expect(locks.runs == ["\(folder)/state.lock"])
    }

    @Test func updateOfMissingFileStartsFromNil() throws {
        let files = FakeFileSystem()
        try StateFolder(files: files, locks: FakeFileLocks(), paths: paths).update("disabled") { $0 ?? "new\n" }
        #expect(files.text(at: "\(folder)/disabled") == "new\n")
    }
}
