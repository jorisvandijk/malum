import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct HomebrewPackagesTests {
    private let brewInstalled = FakeFileSystem(items: ["/opt/homebrew/bin/brew": .file])

    /// A runner whose `brew list` gives `formulae` and `casks`, and whose installs of `failing` fail.
    private func brew(formulae: String = "", casks: String = "", failing: Set<String> = []) -> FakeRunner {
        FakeRunner { command in
            switch command.arguments {
            case ["list", "--formula", "-1"]:
                CommandResult(status: 0, output: formulae)
            case ["list", "--cask", "-1"]:
                CommandResult(status: 0, output: casks)
            case let arguments where arguments.last.map(failing.contains) == true:
                CommandResult(status: 1, errors: "Error: No available formula\n")
            default:
                CommandResult(status: 0)
            }
        }
    }

    private func run(_ settings: ConfigTable, runner: FakeRunner, files: FakeFileSystem? = nil) async -> (
        Bool, [Message]
    ) {
        var messages: [Message] = []
        let succeeded = await HomebrewPackages(runner: runner, files: files ?? brewInstalled).run(settings) {
            messages.append($0)
        }
        return (succeeded, messages)
    }

    @Test func nothingListedRunsNothing() async {
        let runner = brew()
        let (succeeded, messages) = await run([:], runner: runner, files: FakeFileSystem())
        #expect(succeeded)
        #expect(messages.isEmpty)
        #expect(runner.commands.isEmpty)
    }

    @Test func missingPackagesAreInstalled() async {
        let runner = brew(formulae: "bat\n", casks: "")
        let settings: ConfigTable = [
            "formulae": .array([.string("bat"), .string("ripgrep")]), "casks": .array([.string("kitty")]),
        ]
        let (succeeded, messages) = await run(settings, runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands.map(\.arguments).filter { $0.first == "install" } == [
                ["install", "--formula", "ripgrep"], ["install", "--cask", "kitty"],
            ])
        #expect(
            messages == [
                Message(.info, "installing formula ripgrep"), Message(.info, "installed formula ripgrep"),
                Message(.info, "installing cask kitty"), Message(.info, "installed cask kitty"),
            ])
    }

    @Test func installedPackagesAreLeftAlone() async {
        let runner = brew(formulae: "bat\nripgrep\n")
        let (succeeded, messages) = await run(
            ["formulae": .array([.string("bat"), .string("me/tap/ripgrep")])], runner: runner)
        #expect(succeeded)
        #expect(messages == [Message(.info, "every listed formula is installed")])
        #expect(runner.commands.count == 1)
    }

    @Test func packageListedTwiceIsInstalledOnce() async {
        let runner = brew()
        _ = await run(["casks": .array([.string("kitty"), .string("kitty")])], runner: runner)
        #expect(runner.commands.filter { $0.arguments.first == "install" }.count == 1)
    }

    @Test func failedInstallIsReportedAndTheRestGoOn() async {
        let runner = brew(failing: ["nope"])
        let (succeeded, messages) = await run(["formulae": .array([.string("nope"), .string("bat")])], runner: runner)
        #expect(!succeeded)
        #expect(messages.contains(Message(.error, "couldn't install formula nope: Error: No available formula")))
        #expect(messages.last == Message(.info, "installed formula bat"))
    }

    @Test func nameLikeAFlagIsRefused() async {
        let runner = brew()
        let (succeeded, messages) = await run(["formulae": .array([.string("--force")])], runner: runner)
        #expect(!succeeded)
        #expect(messages == [Message(.error, "couldn't install formula --force: it isn't a package name")])
        #expect(runner.commands.count == 1)
    }

    @Test func missingHomebrewIsReported() async {
        let runner = brew()
        let (succeeded, messages) = await run(
            ["formulae": .array([.string("bat")])], runner: runner, files: FakeFileSystem())
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "couldn't install packages: Homebrew isn't installed at /opt/homebrew/bin/brew")
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func failedListingIsReported() async {
        let runner = FakeRunner { _ in CommandResult(status: 1, errors: "Error: broken\n") }
        let (succeeded, messages) = await run(["casks": .array([.string("kitty")])], runner: runner)
        #expect(!succeeded)
        #expect(messages == [Message(.error, "couldn't list the installed casks: Error: broken")])
    }
}
