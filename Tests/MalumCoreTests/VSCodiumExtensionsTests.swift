import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct VSCodiumExtensionsTests {
    private let codiumInstalled = FakeFileSystem(items: ["/opt/homebrew/bin/codium": .file])

    private var state: StateFolder {
        StateFolder(files: codiumInstalled, locks: FakeFileLocks(), paths: Paths(home: "/Users/joris"))
    }

    /// The extensions in the record of what Malum installed.
    private var managed: Set<String> { (try? InstalledRecord.read(from: state).extensions) ?? [] }

    /// A runner whose `codium --list-extensions` gives `installed`, and whose installs and
    /// uninstalls of `failing` fail.
    private func codium(installed: String = "", failing: Set<String> = []) -> FakeRunner {
        FakeRunner { command in
            switch command.arguments.first {
            case "--list-extensions":
                CommandResult(status: 0, output: installed)
            case _ where command.arguments.last.map(failing.contains) == true:
                CommandResult(status: 1)
            default:
                CommandResult(status: 0)
            }
        }
    }

    private func run(_ ids: [String], runner: FakeRunner, files: FakeFileSystem? = nil) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let files = files ?? codiumInstalled
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: Paths(home: "/Users/joris"))
        let succeeded = await VSCodiumExtensions(runner: runner, files: files, state: state).run(ids) {
            messages.append($0)
        }
        return (succeeded, messages)
    }

    @Test func nothingListedRunsNothing() async {
        let runner = codium()
        let (succeeded, messages) = await run([], runner: runner, files: FakeFileSystem())
        #expect(succeeded)
        #expect(messages.isEmpty)
        #expect(runner.commands.isEmpty)
    }

    @Test func missingOnesAreInstalledAndInstalledOnesTakenOverWhateverTheirCase() async {
        let runner = codium(installed: "Dracula-Theme.theme-dracula\n")
        let ids = ["dracula-theme.theme-dracula", "tamasfe.even-better-toml"]
        let (succeeded, messages) = await run(ids, runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Codium.installed, Codium.install("tamasfe.even-better-toml")])
        #expect(
            messages == [
                Message(
                    .info, "VSCodium extension dracula-theme.theme-dracula was already installed, Malum manages it now"),
                Message(.info, "installing VSCodium extension tamasfe.even-better-toml"),
                Message(.info, "installed VSCodium extension tamasfe.even-better-toml"),
            ])
        #expect(managed == Set(ids))
    }

    @Test func unlistedOnesMalumManagesAreUninstalled() async throws {
        try InstalledRecord.change(in: state) { $0.extensions = ["a.gone", "a.old"] }
        let runner = codium(installed: "a.old\n")
        let (succeeded, messages) = await run([], runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Codium.installed, Codium.uninstall("a.old")])
        #expect(
            messages == [
                Message(.info, "VSCodium extension a.gone was already uninstalled"),
                Message(.info, "uninstalling VSCodium extension a.old"),
                Message(.info, "uninstalled VSCodium extension a.old"),
            ])
        #expect(managed.isEmpty)
    }

    @Test func failedInstallIsNotRecorded() async {
        let (succeeded, messages) = await run(["a.bad"], runner: codium(failing: ["a.bad"]))
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't install VSCodium extension a.bad: exited with 1"))
        #expect(managed.isEmpty)
    }

    @Test func withoutCodiumNothingRuns() async {
        let runner = codium()
        let (succeeded, messages) = await run(["a.b"], runner: runner, files: FakeFileSystem())
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    """
                    couldn't install VSCodium extensions: codium isn't installed at /opt/homebrew/bin/codium, \
                    add vscodium = "cask" to [homebrew] in packages.toml
                    """)
            ])
        #expect(runner.commands.isEmpty)
    }
}
