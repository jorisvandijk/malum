import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ComputerSettingsTests {
    private static let asking = Message(.info, "asking for your password to change this Mac's name or boot sound")

    /// A runner where each name `scutil` reads is in `names` (a missing one isn't set), and `nvram`
    /// prints `startupMute`, or fails when it's nil.
    private static func runner(names: [String: String] = [:], startupMute: String? = nil) -> FakeRunner {
        FakeRunner { command in
            if command.executable == Scutil.path, command.arguments.first == "--get" {
                guard let name = command.arguments.last.flatMap({ names[$0] }) else { return CommandResult(status: 1) }
                return CommandResult(status: 0, output: name + "\n")
            }
            guard command == Nvram.readStartupMute else { return CommandResult(status: 0) }
            guard let startupMute else { return CommandResult(status: 1) }
            return CommandResult(status: 0, output: "StartupMute\t\(startupMute)\n")
        }
    }

    /// Writes `wanted` with `runner`, and gives back whether it worked and what it said.
    private func write(_ wanted: ComputerSettings.Wanted, runner: FakeRunner) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let settings = ComputerSettings(runner: runner, sudo: SudoSession(runner: runner, canAsk: true))
        let succeeded = await settings.write(wanted) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func commandsAreBuiltAsScutilAndNvramTakeThem() {
        #expect(Scutil.get(.hostName) == Command("/usr/sbin/scutil", ["--get", "HostName"]))
        #expect(
            Scutil.set(.localHostName, to: "macbook")
                == Command("/usr/sbin/scutil", ["--set", "LocalHostName", "macbook"]))
        #expect(Nvram.setStartupMute(true) == Command("/usr/sbin/nvram", ["StartupMute=%01"]))
        #expect(Nvram.setStartupMute(false) == Command("/usr/sbin/nvram", ["StartupMute=%00"]))
        #expect(Nvram.isMuted("StartupMute\t%01\n"))
        #expect(!Nvram.isMuted("StartupMute\t%00\n"))
    }

    @Test func setsOnlyTheNamesThatDifferAsRoot() async {
        let runner = Self.runner(names: ["ComputerName": "macbook", "HostName": "old"])
        let (succeeded, messages) = await write(ComputerSettings.Wanted(hostname: "macbook"), runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [
                Scutil.get(.computerName), Scutil.get(.hostName), Sudo.authorize,
                Sudo.asRoot(Scutil.set(.hostName, to: "macbook")), Scutil.get(.localHostName),
                Sudo.asRoot(Scutil.set(.localHostName, to: "macbook")),
            ])
        #expect(
            messages == [
                Self.asking,
                Message(.info, "set HostName to macbook from macos.toml"),
                Message(.info, "set LocalHostName to macbook from macos.toml"),
            ])
    }

    @Test func mutesTheBootSoundWhenItPlays() async {
        let runner = Self.runner()
        let (succeeded, messages) = await write(ComputerSettings.Wanted(bootSound: false), runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Nvram.readStartupMute, Sudo.authorize, Sudo.asRoot(Nvram.setStartupMute(true))])
        #expect(messages == [Self.asking, Message(.info, "turned the boot sound off from macos.toml")])
    }

    @Test func leavesWhatAlreadyMatchesWithoutAsking() async {
        let runner = Self.runner(
            names: ["ComputerName": "macbook", "HostName": "macbook", "LocalHostName": "macbook"], startupMute: "%01")
        let (succeeded, messages) = await write(
            ComputerSettings.Wanted(hostname: "macbook", bootSound: false), runner: runner)
        #expect(succeeded)
        #expect(!runner.commands.contains(Sudo.authorize))
        #expect(messages.isEmpty)
    }

    @Test func failedChangeIsReported() async {
        let runner = FakeRunner { command in
            guard command == Sudo.asRoot(Nvram.setStartupMute(false)) else {
                return CommandResult(status: 0, output: "StartupMute\t%01")
            }
            return CommandResult(status: 1, errors: "nvram: Error setting variable")
        }
        let (succeeded, messages) = await write(ComputerSettings.Wanted(bootSound: true), runner: runner)
        #expect(!succeeded)
        #expect(
            messages == [Self.asking, Message(.error, "couldn't set the boot sound: nvram: Error setting variable")])
    }

    @Test func readsTheTableAndRejectsBadValues() {
        let (wanted, _) = MacOSSettings.read("[computer]\nhostname = \"macbook\"\nboot_sound = false\n")
        #expect(wanted?.computer == ComputerSettings.Wanted(hostname: "macbook", bootSound: false))
        let (bad, problems) = MacOSSettings.read(
            "[computer]\nhostname = \"mac book\"\nboot_sound = \"no\"\nname = \"x\"\n")
        #expect(bad == nil)
        #expect(
            problems.map(\.message) == [
                Message(
                    .error,
                    """
                    macos.toml line 2: computer.hostname: a host name holds only letters, digits and dashes, up to \
                    63, and doesn't start or end with a dash
                    """),
                Message(.error, "macos.toml line 3: computer.boot_sound should be true or false"),
                Message(.warn, "macos.toml line 4: unknown setting computer.name"),
            ])
    }
}
