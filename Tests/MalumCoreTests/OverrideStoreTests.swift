import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct OverrideStoreTests {
    let paths = Paths(home: "/Users/test")
    var safeModeFile: String { "\(paths.stateDirectory)/safe-mode" }
    var disabledFile: String { "\(paths.stateDirectory)/disabled" }

    func store(_ files: FakeFileSystem) -> OverrideStore {
        OverrideStore(state: StateFolder(files: files, locks: FakeFileLocks(), paths: paths))
    }

    @Test func nothingSavedMeansNoOverrides() throws {
        #expect(try store(FakeFileSystem()).read() == Overrides())
    }

    @Test func safeModeIsSavedWithItsReason() throws {
        let files = FakeFileSystem()
        try store(files).enterSafeMode(.crashLoop)
        #expect(files.text(at: safeModeFile) == "crash loop\n")
        #expect(try store(files).read() == Overrides(safeMode: .crashLoop))
    }

    @Test func leavingSafeModeEmptiesTheFile() throws {
        let files = FakeFileSystem(texts: [safeModeFile: "asked\n"])
        try store(files).leaveSafeMode()
        #expect(files.text(at: safeModeFile) == "")
        #expect(try store(files).read() == Overrides())
    }

    @Test func unknownReasonStillMeansSafeMode() throws {
        let files = FakeFileSystem(texts: [safeModeFile: "something else\n"])
        #expect(try store(files).read().safeMode == .asked)
    }

    @Test func disabledModulesAreSavedSortedOncePerLine() throws {
        let files = FakeFileSystem(texts: [disabledFile: "samba\n"])
        try store(files).disable("launcher")
        try store(files).disable("samba")
        #expect(files.text(at: disabledFile) == "launcher\nsamba\n")
        #expect(try store(files).read() == Overrides(disabled: ["launcher", "samba"]))
    }

    @Test func enablingRemovesTheModule() throws {
        let files = FakeFileSystem(texts: [disabledFile: "launcher\nsamba\n"])
        try store(files).enable("launcher")
        #expect(files.text(at: disabledFile) == "samba\n")
    }

    @Test func blankLinesAreIgnored() throws {
        let files = FakeFileSystem(texts: [disabledFile: "\n  samba  \n\n"])
        #expect(try store(files).read().disabled == ["samba"])
    }

    @Test func failedWriteIsReported() {
        let files = FakeFileSystem(failing: [safeModeFile])
        #expect(throws: StateError.file(.unwritable(path: safeModeFile, reason: "read-only"))) {
            try store(files).enterSafeMode(.asked)
        }
    }
}
