import Testing

@testable import MalumCore

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct KeyboardModuleTests {
    private let paths = Paths(home: "/Users/test")
    private let files = FakeFileSystem()
    private let runner = FakeRunner()
    private let catcher = FakeKeyCatcher()
    private let keyboardState = FakeKeyboardState()
    private var marker: String { "\(paths.stateDirectory)/\(KeyRemapper.markerName)" }

    /// The module, off, running its commands through `runner`.
    private func module(runner: FakeRunner? = nil) -> KeyboardModule {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        return KeyboardModule(
            system: KeyboardSystem(
                remapper: KeyRemapper(runner: runner ?? self.runner, state: state), keyCatcher: catcher,
                state: keyboardState),
            log: Log(writer: RecordingLogWriter()))
    }

    /// Settings with `text` as the checked `keyboard.toml`, or no file when it's nil.
    private func settings(_ text: String?) -> ModuleSettings {
        ModuleSettings(file: text)
    }

    /// The mapping `text` asks for.
    private func mapping(_ text: String) throws -> KeyMapping {
        KeyMapping(try #require(KeyboardConfig.read(text).config))
    }

    @Test func startCatchesKeysAndSetsTheHyperKey() async throws {
        let text = "hyper_key = \"caps_lock\"\n"
        let keyboard = module()
        keyboard.apply(settings(text))
        try await keyboard.start()
        #expect(catcher.isRunning)
        #expect(runner.commands == [Hidutil.set(try mapping(text))])
        #expect(keyboard.status == .running)
    }

    @Test func withoutAFileItRunsWithNoRemaps() async throws {
        let keyboard = module()
        keyboard.apply(settings(nil))
        try await keyboard.start()
        #expect(catcher.isRunning)
        #expect(runner.commands.isEmpty)
        #expect(keyboard.status == .running)
    }

    @Test func appKeysWarnThatNothingOpensApps() async throws {
        let keyboard = module()
        keyboard.apply(settings("[hyper]\nf = \"com.apple.finder\"\n"))
        try await keyboard.start()
        let problem = ConfigProblem(.warn, file: Paths.moduleTOMLName(KeyboardConfig.module), line: 2, .noAppOpener)
        #expect(keyboard.status == .degraded(reason: problem.message.text.description))
    }

    @Test func refusedTapFailsWithoutRemapping() async throws {
        catcher.refuses = true
        let keyboard = module()
        keyboard.apply(settings("hyper_key = \"caps_lock\"\n"))
        await #expect(throws: KeyboardError.tapRefused) { try await keyboard.start() }
        #expect(runner.commands.isEmpty)
        #expect(keyboard.status == .failed(reason: KeyboardError.tapRefused.text.description))
    }

    @Test func failedRemapStopsTheTap() async throws {
        let failing = FakeRunner { _ in CommandResult(status: 1, errors: "denied") }
        let keyboard = module(runner: failing)
        keyboard.apply(settings("hyper_key = \"caps_lock\"\n"))
        await #expect(throws: KeyRemapError.unset(reason: "denied")) { try await keyboard.start() }
        #expect(!catcher.isRunning)
    }

    @Test func stopLetsGoAndUndoesTheRemaps() async throws {
        let keyboard = module()
        keyboard.apply(settings("hyper_key = \"caps_lock\"\n"))
        try await keyboard.start()
        await keyboard.stop()
        #expect(!catcher.isRunning)
        #expect(runner.commands.last == Hidutil.set(.none))
        #expect(files.text(at: marker) == "")
        #expect(keyboard.status == .off)
    }

    @Test func newSettingsWhileRunningRestartTheTap() async throws {
        let keyboard = module()
        keyboard.apply(settings(""))
        try await keyboard.start()
        let text = "hyper_key = \"caps_lock\"\n"
        keyboard.apply(settings(text))
        await keyboard.stop()
        #expect(catcher.starts == 2)
        #expect(runner.commands.first == Hidutil.set(try mapping(text)))
    }

    @Test func cleanUpUndoesARemapLeftByACrash() async throws {
        let keyboard = module()
        try files.write("{}", to: marker)
        try await keyboard.cleanUp()
        #expect(runner.commands == [Hidutil.set(.none)])
    }

    @Test func secureInputShowsWithTheAppThatHoldsIt() async throws {
        let keyboard = module()
        keyboard.apply(settings("hyper_key = \"caps_lock\"\n"))
        try await keyboard.start()
        keyboardState.secureInput = .on(app: "Terminal")
        keyboard.check()
        #expect(keyboard.status == .degraded(reason: MessageText.secureInput(in: "Terminal").description))
        keyboardState.secureInput = .off
        keyboard.check()
        #expect(keyboard.status == .running)
    }

    @Test func modifierKeysSwapOfTheHyperKeyWarns() async throws {
        let keyboard = module()
        let caps = try #require(Key.named("caps_lock"))
        let escape = try #require(Key.named("escape"))
        keyboardState.modifierSwaps = [
            [
                "HIDKeyboardModifierMappingSrc": try #require(caps.hidUsages.first),
                "HIDKeyboardModifierMappingDst": try #require(escape.hidUsages.first),
            ]
        ]
        keyboard.apply(settings("hyper_key = \"caps_lock\"\n"))
        try await keyboard.start()
        #expect(keyboard.status == .degraded(reason: MessageText.hyperKeySwapped(caps).description))
    }

    @Test func checkLeavesAStoppedModuleOff() async throws {
        let keyboard = module()
        keyboardState.secureInput = .on(app: nil)
        keyboard.check()
        #expect(keyboard.status == .off)
    }

    @Test func resumeStartsTheTapAndSetsTheRemapsAgain() async throws {
        let text = "hyper_key = \"caps_lock\"\n"
        let keyboard = module()
        keyboard.apply(settings(text))
        try await keyboard.start()
        await keyboard.resume()
        #expect(catcher.starts == 2)
        #expect(runner.commands == [Hidutil.set(try mapping(text)), Hidutil.set(try mapping(text))])
        #expect(keyboard.status == .running)
    }

    @Test func tapSwitchedOffIsStartedAgain() async throws {
        let text = "hyper_key = \"caps_lock\"\n"
        let keyboard = module()
        keyboard.apply(settings(text))
        try await keyboard.start()
        catcher.isRunning = false
        keyboard.check()
        await keyboard.resume()
        #expect(catcher.starts == 3)
        #expect(catcher.isRunning)
        #expect(keyboard.status == .running)
    }

    @Test func switchedOffTapThatIsRefusedUndoesTheRemapsAndFails() async throws {
        let text = "hyper_key = \"caps_lock\"\n"
        let keyboard = module()
        keyboard.apply(settings(text))
        try await keyboard.start()
        catcher.isRunning = false
        catcher.refuses = true
        keyboard.check()
        await keyboard.resume()
        #expect(runner.commands == [Hidutil.set(try mapping(text)), Hidutil.set(.none)])
        #expect(files.text(at: marker) == "")
        #expect(keyboard.status == .failed(reason: KeyboardError.tapRefused.text.description))
    }

    @Test func refusedResumeUndoesTheRemapsAndFails() async throws {
        let text = "hyper_key = \"caps_lock\"\n"
        let keyboard = module()
        keyboard.apply(settings(text))
        try await keyboard.start()
        catcher.refuses = true
        await keyboard.resume()
        #expect(runner.commands == [Hidutil.set(try mapping(text)), Hidutil.set(.none)])
        #expect(files.text(at: marker) == "")
        #expect(keyboard.status == .failed(reason: KeyboardError.tapRefused.text.description))
    }

    @Test func failedRemapWhileRunningUndoesTheRemapsAndStopsTheTap() async throws {
        let first = "hyper_key = \"caps_lock\"\n"
        let second = "hyper_key = \"caps_lock\"\n\n[remap]\nescape = \"grave\"\n"
        let refused = Hidutil.set(try mapping(second))
        let failing = FakeRunner { command in
            guard command == refused else { return CommandResult(status: 0) }
            return CommandResult(status: 1, errors: "denied")
        }
        let keyboard = module(runner: failing)
        keyboard.apply(settings(first))
        try await keyboard.start()
        keyboard.apply(settings(second))
        await keyboard.resume()
        #expect(failing.commands.contains(refused))
        #expect(failing.commands.last == Hidutil.set(.none))
        #expect(files.text(at: marker) == "")
        #expect(!catcher.isRunning)
        #expect(keyboard.status == .failed(reason: KeyRemapError.unset(reason: "denied").text.description))
    }

    @Test func stopWaitsForEveryRestart() async throws {
        let keyboard = module()
        keyboard.apply(settings(""))
        try await keyboard.start()
        keyboard.apply(settings(""))
        keyboard.apply(settings(""))
        await keyboard.stop()
        #expect(catcher.starts == 3)
        #expect(!catcher.isRunning)
        #expect(keyboard.status == .off)
    }

    @Test func resumeLeavesAStoppedModuleAlone() async throws {
        let keyboard = module()
        await keyboard.resume()
        #expect(catcher.starts == 0)
        #expect(runner.commands.isEmpty)
    }
}
