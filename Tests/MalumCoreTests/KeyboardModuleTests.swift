import Testing

@testable import MalumCore

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct KeyboardModuleTests {
    private let paths = Paths(home: "/Users/test")
    private let files = FakeFileSystem()
    private let runner = FakeRunner()
    private let catcher = FakeKeyCatcher()
    private let dots = "/dots"
    private var marker: String { "\(paths.stateDirectory)/\(KeyRemapper.markerName)" }

    /// The module, with `text` as `keyboard.toml` in dots, or no dots at all when it's nil.
    private func module(_ text: String?, runner: FakeRunner? = nil) throws -> KeyboardModule {
        if let text {
            try DotsPointer(files: files, paths: paths).write(dots)
            try files.write(text, to: paths.moduleTOML(KeyboardConfig.module, in: dots))
        }
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        return KeyboardModule(
            files: files, paths: paths, remapper: KeyRemapper(runner: runner ?? self.runner, state: state),
            keyCatcher: catcher, log: Log(writer: RecordingLogWriter()))
    }

    /// The mapping `text` asks for.
    private func mapping(_ text: String) throws -> KeyMapping {
        KeyMapping(try #require(KeyboardConfig.read(text).config))
    }

    @Test func startCatchesKeysAndSetsTheHyperKey() async throws {
        let text = "hyper_key = \"caps_lock\"\n"
        let keyboard = try module(text)
        try keyboard.apply([:])
        try await keyboard.start()
        #expect(catcher.isRunning)
        #expect(runner.commands == [Hidutil.set(try mapping(text))])
        #expect(keyboard.status == .running)
    }

    @Test func withoutDotsItRunsWithNoRemaps() async throws {
        let keyboard = try module(nil)
        try keyboard.apply([:])
        try await keyboard.start()
        #expect(catcher.isRunning)
        #expect(runner.commands.isEmpty)
        #expect(keyboard.status == .running)
    }

    @Test func appKeysWarnThatNothingOpensApps() async throws {
        let keyboard = try module("[hyper]\nf = \"com.apple.finder\"\n")
        try keyboard.apply([:])
        try await keyboard.start()
        let problem = ConfigProblem(.warn, file: Paths.moduleTOMLName(KeyboardConfig.module), line: 2, .noAppOpener)
        #expect(keyboard.status == .degraded(reason: problem.message.text.description))
    }

    @Test func refusedTapFailsWithoutRemapping() async throws {
        catcher.refuses = true
        let keyboard = try module("hyper_key = \"caps_lock\"\n")
        try keyboard.apply([:])
        await #expect(throws: KeyboardError.tapRefused) { try await keyboard.start() }
        #expect(runner.commands.isEmpty)
        #expect(keyboard.status == .failed(reason: KeyboardError.tapRefused.text.description))
    }

    @Test func failedRemapStopsTheTap() async throws {
        let failing = FakeRunner { _ in CommandResult(status: 1, errors: "denied") }
        let keyboard = try module("hyper_key = \"caps_lock\"\n", runner: failing)
        try keyboard.apply([:])
        await #expect(throws: KeyRemapError.unset(reason: "denied")) { try await keyboard.start() }
        #expect(!catcher.isRunning)
    }

    @Test func stopLetsGoAndUndoesTheRemaps() async throws {
        let keyboard = try module("hyper_key = \"caps_lock\"\n")
        try keyboard.apply([:])
        try await keyboard.start()
        await keyboard.stop()
        #expect(!catcher.isRunning)
        #expect(runner.commands.last == Hidutil.set(.none))
        #expect(files.text(at: marker) == "")
        #expect(keyboard.status == .off)
    }

    @Test func newSettingsWhileRunningRestartTheTap() async throws {
        let keyboard = try module("")
        try keyboard.apply([:])
        try await keyboard.start()
        let text = "hyper_key = \"caps_lock\"\n"
        try files.write(text, to: paths.moduleTOML(KeyboardConfig.module, in: dots))
        try keyboard.apply([:])
        await keyboard.stop()
        #expect(catcher.starts == 2)
        #expect(runner.commands.first == Hidutil.set(try mapping(text)))
    }

    @Test func badFileKeepsTheLastGoodSettings() async throws {
        let keyboard = try module("hyper_key = \"caps_lock\"\n")
        try keyboard.apply([:])
        try files.write("hyper_key = \"nope\"\n", to: paths.moduleTOML(KeyboardConfig.module, in: dots))
        let problem = ConfigProblem(.error, .fixFirst(Paths.moduleTOMLName(KeyboardConfig.module)))
        #expect(throws: problem) { try keyboard.apply([:]) }
        try await keyboard.start()
        #expect(runner.commands == [Hidutil.set(try mapping("hyper_key = \"caps_lock\"\n"))])
    }

    @Test func cleanUpUndoesARemapLeftByACrash() async throws {
        let keyboard = try module(nil)
        try files.write("{}", to: marker)
        try await keyboard.cleanUp()
        #expect(runner.commands == [Hidutil.set(.none)])
    }
}
