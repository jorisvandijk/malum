import Synchronization
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ScreenLockSettingsTests {
    nonisolated private static let off = "sysadminctl[812:4410] screenLock is off\n"
    nonisolated private static let immediate = "sysadminctl[812:4410] screenLock delay is immediate\n"
    nonisolated private static let fiveMinutes = "sysadminctl[812:4410] screenLock delay is 300 seconds\n"
    private static let asking = Message(
        .info, "asking for your password to change when the screen asks for your password")

    /// A runner whose `sysadminctl` prints `status` to stderr, and changes it to what it's asked
    /// for when `accepts` is set.
    private static func runner(status: String, accepts: Bool = true) -> FakeRunner {
        let current = Mutex(status)
        return FakeRunner { command in
            guard command != Sysadminctl.screenLockStatus else {
                return CommandResult(status: 0, errors: current.withLock { $0 })
            }
            if accepts, command == Sysadminctl.setScreenLock(after: 0) {
                current.withLock { $0 = immediate }
            }
            return CommandResult(status: 0)
        }
    }

    /// Reads `toml` as `macos.toml`, and gives back the seconds it sets and every problem.
    private func read(_ toml: String) -> (Int?, [Message]) {
        let (wanted, problems) = MacOSSettings.read(toml)
        return (wanted?.screenLock, problems.map(\.message))
    }

    /// Sets `wanted` with `runner`, and gives back whether it worked and what it said.
    private func set(_ wanted: Int?, runner: FakeRunner, canAsk: Bool = true) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let settings = ScreenLockSettings(runner: runner, sudo: SudoSession(runner: runner, canAsk: canAsk))
        let succeeded = await settings.set(wanted) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func commandsAreBuiltAsSysadminctlTakesThem() {
        #expect(Sysadminctl.screenLockStatus == Command("/usr/sbin/sysadminctl", ["-screenLock", "status"]))
        let immediate = Sysadminctl.setScreenLock(after: 0)
        #expect(immediate.arguments == ["-screenLock", "immediate", "-password", "-"])
        #expect(immediate.onTerminal)
        #expect(Sysadminctl.setScreenLock(after: 60).arguments == ["-screenLock", "60", "-password", "-"])
    }

    @Test func statusIsReadFromWhatSysadminctlPrints() {
        #expect(Sysadminctl.screenLock(in: Self.off) == .off)
        #expect(Sysadminctl.screenLock(in: Self.immediate) == .after(0))
        #expect(Sysadminctl.screenLock(in: Self.fiveMinutes) == .after(300))
        #expect(Sysadminctl.screenLock(in: "") == nil)
    }

    @Test func readsTheDelay() {
        let (seconds, problems) = read("[screen_lock]\ndelay_seconds = 0\n")
        #expect(problems.isEmpty)
        #expect(seconds == 0)
    }

    @Test(arguments: ["-1", "\"immediate\"", "true"])
    func delayThatIsntSecondsReportsLine(text: String) {
        let (seconds, problems) = read("[screen_lock]\ndelay_seconds = \(text)\n")
        #expect(seconds == nil)
        #expect(
            problems == [
                Message(
                    .error,
                    "macos.toml line 2: screen_lock.delay_seconds should be \(CatalogValue.seconds(0...Int.max))")
            ])
    }

    @Test func unknownKeyReportsLine() {
        let (_, problems) = read("[screen_lock]\nask = true\n")
        #expect(problems == [Message(.warn, "macos.toml line 2: unknown setting screen_lock.ask")])
    }

    @Test func setsItWhenItDiffers() async {
        let runner = Self.runner(status: Self.off)
        let (succeeded, messages) = await set(0, runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands == [
                Sysadminctl.screenLockStatus, Sysadminctl.setScreenLock(after: 0), Sysadminctl.screenLockStatus,
            ])
        #expect(
            messages == [
                Self.asking,
                Message(.info, "the screen asks for your password as soon as it goes black now, from macos.toml"),
            ])
    }

    @Test func leavesItAloneWithoutAskingWhenItMatches() async {
        let runner = Self.runner(status: Self.immediate)
        let (succeeded, messages) = await set(0, runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Sysadminctl.screenLockStatus])
        #expect(messages.isEmpty)
    }

    @Test func noDelaySetsNothing() async {
        let runner = Self.runner(status: Self.off)
        let (succeeded, messages) = await set(nil, runner: runner)
        #expect(succeeded)
        #expect(runner.commands.isEmpty)
        #expect(messages.isEmpty)
    }

    @Test func refusedPasswordIsReported() async {
        let runner = Self.runner(status: Self.fiveMinutes, accepts: false)
        let (succeeded, messages) = await set(0, runner: runner)
        #expect(!succeeded)
        #expect(
            messages == [
                Self.asking,
                Message(
                    .error,
                    "couldn't change when the screen asks for your password: macOS didn't take it, check the password"),
            ])
    }

    @Test func noTerminalIsReportedWithoutRunningIt() async {
        let runner = Self.runner(status: Self.off)
        let (succeeded, messages) = await set(0, runner: runner, canAsk: false)
        #expect(!succeeded)
        #expect(runner.commands == [Sysadminctl.screenLockStatus])
        #expect(
            messages == [
                Message(
                    .error,
                    "couldn't change when the screen asks for your password: it needs your password, so run it from a terminal"
                )
            ])
    }
}
