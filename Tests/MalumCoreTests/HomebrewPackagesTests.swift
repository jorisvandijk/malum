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

    private func run(_ packages: [PackageKind: [String]], runner: FakeRunner, files: FakeFileSystem? = nil) async -> (
        Bool, [Message]
    ) {
        var messages: [Message] = []
        let succeeded = await HomebrewPackages(runner: runner, files: files ?? brewInstalled).run(packages) {
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
        let (succeeded, messages) = await run([.cask: ["kitty"], .formula: ["bat", "ripgrep"]], runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands.map(\.arguments).filter { $0.first == "install" } == [
                ["install", "--formula", "ripgrep"], ["install", "--cask", "kitty"],
            ])
        #expect(
            messages == [
                Message(.info, "installing Homebrew formula ripgrep"),
                Message(.info, "installed Homebrew formula ripgrep"),
                Message(.info, "installing Homebrew cask kitty"), Message(.info, "installed Homebrew cask kitty"),
            ])
    }

    @Test func installedPackagesAreLeftAlone() async {
        let runner = brew(formulae: "bat\nripgrep\n")
        let (succeeded, messages) = await run(
            [.formula: ["bat", "me/tap/ripgrep"]], runner: runner)
        #expect(succeeded)
        #expect(messages == [Message(.info, "every listed Homebrew formula is installed")])
        #expect(runner.commands.count == 1)
    }

    @Test func failedInstallIsReportedAndTheRestGoOn() async {
        let runner = brew(failing: ["nope"])
        let (succeeded, messages) = await run([.formula: ["nope", "bat"]], runner: runner)
        #expect(!succeeded)
        #expect(
            messages.contains(Message(.error, "couldn't install Homebrew formula nope: Error: No available formula")))
        #expect(messages.last == Message(.info, "installed Homebrew formula bat"))
    }

    @Test func nameLikeAFlagIsRefused() async {
        let runner = brew()
        let (succeeded, messages) = await run([.formula: ["--force"]], runner: runner)
        #expect(!succeeded)
        #expect(messages == [Message(.error, "couldn't install Homebrew formula --force: it isn't a package name")])
        #expect(runner.commands.count == 1)
    }

    @Test func missingHomebrewIsReported() async {
        let runner = brew()
        let (succeeded, messages) = await run(
            [.formula: ["bat"]], runner: runner, files: FakeFileSystem())
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "couldn't install packages: Homebrew isn't installed at /opt/homebrew/bin/brew")
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func failedListingIsReported() async {
        let runner = FakeRunner { _ in CommandResult(status: 1, errors: "Error: broken\n") }
        let (succeeded, messages) = await run([.cask: ["kitty"]], runner: runner)
        #expect(!succeeded)
        #expect(messages == [Message(.error, "couldn't list the installed Homebrew casks: Error: broken")])
    }
}
