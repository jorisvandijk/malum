import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct RunCommandTests {
    private let paths = Paths(home: "/Users/joris")
    private let pointer = "/Users/joris/.config/malum/config"
    private let file = "/Users/joris/dots/malum.toml"
    private let packages = "/Users/joris/dots/packages.toml"
    private let switchedOn = "[system_config]\nenabled = true\n"

    private func run(
        _ toml: String?, packages list: String? = nil, runner: FakeRunner = FakeRunner(), more: [String: String] = [:]
    ) async -> (Bool, [Message]) {
        var texts = more.merging([pointer: "/Users/joris/dots\n"]) { $1 }
        texts[file] = toml
        texts[packages] = list
        let files = FakeFileSystem(
            items: ["/opt/homebrew/bin/brew": .file, "/opt/homebrew/bin/mas": .file], texts: texts)
        var messages: [Message] = []
        let succeeded = await RunCommand(
            files: files, paths: paths, runner: runner, github: FakeGitHub([:], files: files), locks: FakeFileLocks(),
            canAsk: true, handlers: FakeAppHandlers()
        ).run {
            messages.append($0)
        }
        return (succeeded, messages)
    }

    @Test func switchedOnInstallsWhatPackagesTomlLists() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run(switchedOn, packages: "[homebrew]\nbat = \"formula\"\n", runner: runner)
        #expect(succeeded)
        #expect(runner.commands.last?.arguments == ["install", "--formula", "bat"])
        #expect(messages.last == Message(.info, "system_config is done"))
    }

    @Test func missingPackagesTomlInstallsNothing() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run(switchedOn, runner: runner)
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "nothing to install: \(packages) doesn't exist"),
                Message(.info, "no app config files to write: /Users/joris/dots/apps doesn't exist"),
                Message(.info, "no macOS settings to set: /Users/joris/dots/macos.toml doesn't exist"),
                Message(.info, "system_config is done"),
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func badPackagesTomlInstallsNothing() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run(
            switchedOn, packages: "[homebrew]\nbat = \"formula\"\nkitty = \"app\"\n", runner: runner)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "packages.toml line 3: homebrew.kitty should be \"formula\" or \"cask\""),
                Message(.error, "couldn't install packages: fix \(packages) first"),
                Message(.info, "no app config files to write: /Users/joris/dots/apps doesn't exist"),
                Message(.info, "no macOS settings to set: /Users/joris/dots/macos.toml doesn't exist"),
                Message(.error, "system_config finished with errors"),
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func switchedOffRunsNothing() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run(
            "[system_config]\n", packages: "[homebrew]\nbat = \"formula\"\n", runner: runner)
        #expect(!succeeded)
        #expect(
            messages == [
                Message(.error, "couldn't run system_config: it's off, set enabled = true in its table in \(file)")
            ])
        #expect(runner.commands.isEmpty)
    }

    @Test func badTableRunsNothing() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run("[system_config]\nenabled = true\nformulae = [\"bat\"]\n", runner: runner)
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "couldn't run system_config: fix its table in \(file) first"))
        #expect(messages.contains(Message(.error, "malum.toml line 3: unknown setting system_config.formulae")))
        #expect(runner.commands.isEmpty)
    }

    @Test func missingFileIsReported() async {
        let (succeeded, messages) = await run(nil)
        #expect(!succeeded)
        #expect(messages == [Message(.error, "couldn't load \(file): it doesn't exist")])
    }

    @Test func failedInstallEndsWithAnError() async {
        let runner = FakeRunner { command in
            CommandResult(status: command.arguments.first == "install" ? 1 : 0, errors: "Error: nope\n")
        }
        let (succeeded, messages) = await run(switchedOn, packages: "[homebrew]\nkitty = \"cask\"\n", runner: runner)
        #expect(!succeeded)
        #expect(messages.last == Message(.error, "system_config finished with errors"))
    }

    @Test func appStoreAppsInstallAfterHomebrew() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run(
            switchedOn, packages: "[app_store]\nxcode = 497799835\n\n[homebrew]\nmas = \"formula\"\n", runner: runner)
        #expect(succeeded)
        #expect(
            runner.commands.map { $0.arguments.first ?? "" } == ["list", "install", "list", "-v", "-n"])
        #expect(messages.last == Message(.info, "system_config is done"))
    }

    @Test func releasesInstallLastWithTheFoldersFromMalumToml() async {
        let (succeeded, messages) = await run(
            "[system_config]\nenabled = true\nrelease_programs = \"~/bin\"\n",
            packages: "[release.ghost]\nrepo = \"nobody/ghost\"\n")
        #expect(!succeeded)
        #expect(
            messages == [
                Message(
                    .error,
                    "couldn't install GitHub release ghost: nobody/ghost has no published release on GitHub, or it's private"
                ),
                Message(.info, "no app config files to write: /Users/joris/dots/apps doesn't exist"),
                Message(.info, "no macOS settings to set: /Users/joris/dots/macos.toml doesn't exist"),
                Message(.error, "system_config finished with errors"),
            ])
    }

    @Test func appConfigFilesAreWrittenAfterThePackages() async {
        let (succeeded, messages) = await run(
            switchedOn, more: ["/Users/joris/dots/apps/git.toml": "[settings.init]\ndefaultBranch = \"main\"\n"])
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "nothing to install: \(packages) doesn't exist"),
                Message(.info, "wrote /Users/joris/.config/git/config from apps/git.toml"),
                Message(.info, "no macOS settings to set: /Users/joris/dots/macos.toml doesn't exist"),
                Message(.info, "system_config is done"),
            ])
    }

    @Test func macOSSettingsAreSetLast() async {
        let runner = FakeRunner { command in
            guard command.arguments.first == "export" else { return CommandResult(status: 0) }
            return CommandResult(status: 0, output: "<plist version=\"1.0\"><dict/></plist>")
        }
        let (succeeded, messages) = await run(
            switchedOn, runner: runner,
            more: ["/Users/joris/dots/macos.toml": "[preferences.\"com.apple.dock\"]\nautohide = true\n"])
        #expect(succeeded)
        #expect(
            messages == [
                Message(.info, "nothing to install: \(packages) doesn't exist"),
                Message(.info, "no app config files to write: /Users/joris/dots/apps doesn't exist"),
                Message(.info, "set autohide in com.apple.dock from macos.toml"),
                Message(.info, "restarted Dock to use the new settings"),
                Message(.info, "system_config is done"),
            ])
    }
}
