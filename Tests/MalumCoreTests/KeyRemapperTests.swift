import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct KeyRemapperTests {
    private let paths = Paths(home: "/Users/test")
    private var marker: String { "\(paths.stateDirectory)/\(KeyRemapper.markerName)" }

    private func remapper(_ files: FakeFileSystem, _ runner: FakeRunner) -> KeyRemapper {
        KeyRemapper(runner: runner, state: StateFolder(files: files, locks: FakeFileLocks(), paths: paths))
    }

    /// The key called `name`, which the test knows is one.
    private func key(_ name: String) throws -> Key {
        try #require(Key.named(name))
    }

    private func capsLock() throws -> KeyMapping {
        KeyMapping(KeyboardConfig(hyperKey: try key("caps_lock")))
    }

    @Test func applyMarksThenSets() async throws {
        let files = FakeFileSystem()
        let runner = FakeRunner()
        let mapping = try capsLock()
        try await remapper(files, runner).apply(mapping)
        #expect(runner.commands == [Hidutil.set(mapping)])
        #expect(files.text(at: marker) == mapping.json)
    }

    @Test func failedSetKeepsTheMarker() async throws {
        let files = FakeFileSystem()
        let runner = FakeRunner { _ in CommandResult(status: 1, errors: "denied") }
        let mapping = try capsLock()
        await #expect(throws: KeyRemapError.unset(reason: "denied")) {
            try await remapper(files, runner).apply(mapping)
        }
        #expect(files.text(at: marker) == mapping.json)
    }

    @Test func applyFailsWithoutRemappingWhenTheMarkerCantBeWritten() async throws {
        let runner = FakeRunner()
        await #expect(throws: KeyRemapError.marker(.file(.unwritable(path: marker, reason: "read-only")))) {
            try await remapper(FakeFileSystem(failing: [marker]), runner).apply(try capsLock())
        }
        #expect(runner.commands.isEmpty)
    }

    @Test func applyingNoneClears() async throws {
        let files = FakeFileSystem(texts: [marker: "{}"])
        let runner = FakeRunner()
        try await remapper(files, runner).apply(.none)
        #expect(runner.commands == [Hidutil.set(.none)])
        #expect(files.text(at: marker) == "")
    }

    @Test func clearUndoesARemapLeftByACrash() async throws {
        let files = FakeFileSystem(texts: [marker: "{}"])
        let runner = FakeRunner()
        try await remapper(files, runner).clear()
        #expect(runner.commands == [Hidutil.set(.none)])
        #expect(files.text(at: marker) == "")
    }

    @Test func clearLeavesOtherMappingsWithoutAMarker() async throws {
        let runner = FakeRunner()
        try await remapper(FakeFileSystem(), runner).clear()
        try await remapper(FakeFileSystem(texts: [marker: ""]), runner).clear()
        #expect(runner.commands.isEmpty)
    }

    @Test func failedClearKeepsTheMarker() async throws {
        let files = FakeFileSystem(texts: [marker: "{}"])
        let runner = FakeRunner { _ in CommandResult(status: 1) }
        await #expect(throws: KeyRemapError.uncleared(reason: "exited with 1")) {
            try await remapper(files, runner).clear()
        }
        #expect(files.text(at: marker) == "{}")
    }

    @Test func errorsSayWhatFailed() {
        #expect(KeyRemapError.unset(reason: "denied").description == "couldn't remap the keys: denied")
        #expect(KeyRemapError.uncleared(reason: "denied").description == "couldn't undo the key remaps: denied")
    }
}
