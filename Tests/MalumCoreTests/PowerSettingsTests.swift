import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct PowerSettingsTests {
    private let paths = Paths(home: "/Users/test")
    nonisolated private static let custom = """
        Battery Power:
         lessbright           1
         displaysleep         2
        AC Power:
         lessbright           1
         Sleep On Power Button 1

        """

    /// A runner whose `pmset -g custom` prints `output`.
    private static func runner(_ output: String = custom) -> FakeRunner {
        FakeRunner { $0 == Pmset.custom ? CommandResult(status: 0, output: output) : CommandResult(status: 0) }
    }

    /// Writes `wanted` on `files` with `runner`, and gives back whether it worked and what it said.
    private func write(
        _ wanted: PowerSettings.Wanted, _ files: FakeFileSystem, runner: FakeRunner
    ) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        let writer = PowerSettings(runner: runner, sudo: SudoSession(runner: runner, canAsk: true), state: state)
        let succeeded = await writer.write(wanted) { messages.append($0) }
        return (succeeded, messages)
    }

    private func state(_ files: FakeFileSystem) -> StateFolder {
        StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
    }

    private func record(_ files: FakeFileSystem) -> [String: [String: ManagedPower]] {
        ((try? InstalledRecord.read(from: state(files))) ?? InstalledRecord()).power
    }

    private static let asking = Message(.info, "asking for your password to change power settings")

    @Test func pmsetOutputIsReadBySource() {
        #expect(
            Pmset.settings(in: Self.custom) == [
                .battery: ["lessbright": 1, "displaysleep": 2],
                .charger: ["lessbright": 1, "Sleep On Power Button": 1],
            ])
        #expect(Pmset.set("lessbright", to: 0, on: .battery) == Command("/usr/bin/pmset", ["-b", "lessbright", "0"]))
    }

    @Test func setsAsRootAndRemembersTheOriginal() async {
        let runner = Self.runner()
        let files = FakeFileSystem()
        let (succeeded, messages) = await write(
            [.battery: ["lessbright": 0, "displaysleep": 2]], files, runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [
                Pmset.custom, Sudo.authorize, Sudo.asRoot(Pmset.set("lessbright", to: 0, on: .battery)),
            ])
        #expect(
            messages == [
                Self.asking, Message(.info, "set lessbright on battery power to 0 from macos.toml (it was 1)"),
            ])
        #expect(
            record(files) == [
                "battery": [
                    "lessbright": ManagedPower(value: 0, original: 1),
                    "displaysleep": ManagedPower(value: 2, original: 2),
                ]
            ])
    }

    @Test func nothingWantedOrRecordedRunsNothing() async {
        let runner = Self.runner()
        let (succeeded, messages) = await write([:], FakeFileSystem(), runner: runner)
        #expect(succeeded)
        #expect(runner.commands.isEmpty)
        #expect(messages.isEmpty)
    }

    @Test func droppedSettingGoesBackToTheOriginal() async {
        let runner = Self.runner(Self.custom.replacingOccurrences(of: "lessbright           1\n AC", with: "x"))
        let files = FakeFileSystem()
        try? InstalledRecord.change(in: state(files)) {
            $0.power = ["charger": ["lessbright": ManagedPower(value: 1, original: 0)]]
        }
        let (succeeded, messages) = await write([:], files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands.last == Sudo.asRoot(Pmset.set("lessbright", to: 0, on: .charger)))
        #expect(
            messages.last
                == Message(.info, "set lessbright on charger power back to 0, macos.toml doesn't set it anymore"))
        #expect(record(files).isEmpty)
    }

    @Test func droppedSettingChangedByHandIsLetGo() async {
        let runner = Self.runner()
        let files = FakeFileSystem()
        try? InstalledRecord.change(in: state(files)) {
            $0.power = ["battery": ["lessbright": ManagedPower(value: 0, original: 1)]]
        }
        try? InstalledRecord.change(in: state(files)) {
            $0.power["battery"]?["displaysleep"] = ManagedPower(value: 5, original: 2)
        }
        let (succeeded, messages) = await write([:], files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Pmset.custom])
        #expect(
            messages == [
                Message(
                    .warn,
                    """
                    displaysleep on battery power isn't set from macos.toml anymore, but it was changed outside \
                    Malum, so it stays and Malum no longer manages it
                    """),
                Message(
                    .warn,
                    """
                    lessbright on battery power isn't set from macos.toml anymore, but it was changed outside \
                    Malum, so it stays and Malum no longer manages it
                    """),
            ])
        #expect(record(files).isEmpty)
    }

    @Test func missingSourceIsSkippedAndUnknownSettingFails() async {
        let runner = Self.runner("Battery Power:\n lessbright 1\n")
        let (succeeded, messages) = await write(
            [.battery: ["lidwake": 1], .charger: ["lessbright": 0]], FakeFileSystem(), runner: runner)
        #expect(!succeeded)
        #expect(runner.commands == [Pmset.custom])
        #expect(
            messages == [
                Message(
                    .error,
                    "couldn't set lidwake on battery power: pmset has no such setting, pmset -g custom lists them"),
                Message(.warn, "this Mac has no charger power, so [power.charger] in macos.toml was skipped"),
            ])
    }

    @Test func refusedPasswordSetsNothing() async {
        let runner = FakeRunner {
            switch $0 {
            case Pmset.custom: CommandResult(status: 0, output: Self.custom)
            case Sudo.authorize: CommandResult(status: 1)
            default: CommandResult(status: 0)
            }
        }
        let files = FakeFileSystem()
        let (succeeded, messages) = await write([.battery: ["lessbright": 0]], files, runner: runner)
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't change power settings: sudo wasn't granted"))
        #expect(record(files).isEmpty)
    }
}
