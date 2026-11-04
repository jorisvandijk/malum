import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct HomebrewPackagesTests {
    private let brewInstalled = FakeFileSystem(items: ["/opt/homebrew/bin/brew": .file])

    private var state: StateFolder {
        StateFolder(files: brewInstalled, locks: FakeFileLocks(), paths: Paths(home: "/Users/joris"))
    }

    /// The record of what Malum installed, on the disk where brew is installed.
    private var record: InstalledRecord { (try? InstalledRecord.read(from: state)) ?? InstalledRecord() }

    /// Records `formulae` and `casks` as managed by Malum.
    private func manage(formulae: Set<String> = [], casks: Set<String> = []) throws {
        try InstalledRecord.change(in: state) { record in
            record.formulae = formulae
            record.casks = casks
        }
    }

    /// A runner whose `brew list` gives `formulae` and `casks`, whose installs and uninstalls of
    /// `failing` fail, and whose uninstalls of `needed` fail because other packages need them.
    private func brew(
        formulae: String = "", casks: String = "", failing: Set<String> = [], needed: Set<String> = []
    ) -> FakeRunner {
        FakeRunner { command in
            switch command.arguments {
            case ["list", "--formula", "-1"]:
                CommandResult(status: 0, output: formulae)
            case ["list", "--cask", "-1"]:
                CommandResult(status: 0, output: casks)
            case let arguments where arguments.last.map(needed.contains) == true:
                CommandResult(
                    status: 1,
                    errors:
                        "Error: Refusing to uninstall /opt/homebrew/Cellar/libyaml\nbecause it is required by ruby\n")
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
        let files = files ?? brewInstalled
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: Paths(home: "/Users/joris"))
        let succeeded = await HomebrewPackages(runner: runner, files: files, state: state).run(packages) {
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
                Message(.info, "Homebrew formula bat was already installed, Malum manages it now"),
                Message(.info, "installing Homebrew formula ripgrep"),
                Message(.info, "installed Homebrew formula ripgrep"),
                Message(.info, "installing Homebrew cask kitty"), Message(.info, "installed Homebrew cask kitty"),
            ])
    }

    @Test func installedPackagesAreTakenOverOnce() async {
        let runner = brew(formulae: "bat\nripgrep\n")
        let (succeeded, messages) = await run([.formula: ["bat", "me/tap/ripgrep"]], runner: runner)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "Homebrew formula bat was already installed, Malum manages it now"),
                Message(.info, "Homebrew formula me/tap/ripgrep was already installed, Malum manages it now"),
                Message(.info, "every listed Homebrew formula is installed"),
            ])
        #expect(runner.commands.count == 1)
        #expect(record.formulae == ["bat", "me/tap/ripgrep"])
        let (_, again) = await run([.formula: ["bat", "me/tap/ripgrep"]], runner: runner)
        #expect(again == [Message(.info, "every listed Homebrew formula is installed")])
    }

    @Test func installsAreRecorded() async {
        _ = await run([.cask: ["kitty"], .formula: ["bat"]], runner: brew())
        #expect(record.formulae == ["bat"])
        #expect(record.casks == ["kitty"])
    }

    @Test func unlistedPackagesMalumManagesAreUninstalled() async throws {
        try manage(formulae: ["bat", "jq"], casks: ["kitty"])
        let runner = brew(formulae: "bat\njq\nripgrep\n")
        let (succeeded, messages) = await run([.formula: ["bat"]], runner: runner)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "every listed Homebrew formula is installed"),
                Message(.info, "uninstalling Homebrew formula jq"),
                Message(.info, "uninstalled Homebrew formula jq"),
                Message(.info, "Homebrew cask kitty was already uninstalled"),
            ])
        #expect(
            runner.commands.map(\.arguments).filter { $0.first == "uninstall" } == [["uninstall", "--formula", "jq"]])
        #expect(record.formulae == ["bat"])
        #expect(record.casks.isEmpty)
    }

    @Test func neededFormulaStaysAndIsNoLongerManaged() async throws {
        try manage(formulae: ["libyaml"])
        let (succeeded, messages) = await run(
            [:], runner: brew(formulae: "libyaml\nruby\n", needed: ["libyaml"]))
        #expect(succeeded)
        #expect(
            messages.last
                == Message(
                    .warn,
                    "Homebrew formula libyaml is still needed by other packages, so it stays and Malum no longer manages it"
                ))
        #expect(record.formulae.isEmpty)
    }

    @Test func failedUninstallStaysManaged() async throws {
        try manage(casks: ["kitty"])
        let (succeeded, messages) = await run([:], runner: brew(casks: "kitty\n", failing: ["kitty"]))
        #expect(!succeeded)
        #expect(
            messages.last == Message(.error, "couldn't uninstall Homebrew cask kitty: Error: No available formula"))
        #expect(record.casks == ["kitty"])
    }

    @Test func unreadableRecordStopsThePart() async throws {
        try brewInstalled.write("not json", to: state.path(of: "installed.json"))
        let runner = brew()
        let (succeeded, messages) = await run([.formula: ["bat"]], runner: runner)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    """
                    couldn't install packages: couldn't read /Users/joris/Library/Application Support/\
                    com.jorisvandijk.malum/installed.json, the record of what Malum installed
                    """)
            ])
        #expect(runner.commands.isEmpty)
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
