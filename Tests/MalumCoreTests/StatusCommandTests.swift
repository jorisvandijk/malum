import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct StatusCommandTests {
    private let paths = Paths(home: "/Users/test")
    private let pointer = "/Users/test/.config/malum/config"
    private let packages = "/Users/test/dots/packages.toml"
    private let kittyConf = "/Users/test/.config/kitty/kitty.conf"
    private let hosts = "/etc/hosts"

    /// A runner whose `brew list --formula` gives `formulae`, whose `mas list` gives `apps`, and
    /// whose `pmset -g custom` gives `power`.
    private static func runner(formulae: String = "", apps: String = "", power: String = "") -> FakeRunner {
        FakeRunner { command in
            switch command {
            case Brew.installed(.formula):
                CommandResult(status: 0, output: formulae)
            case Mas.installed:
                CommandResult(status: 0, output: apps)
            case Pmset.custom:
                CommandResult(status: 0, output: power)
            default:
                CommandResult(status: 0)
            }
        }
    }

    /// Runs the status on a disk holding `texts` and dots, after `change` to the record, and gives
    /// back whether it could tell everything and what it said.
    private func status(
        _ texts: [String: String] = [:], runner: FakeRunner = FakeRunner(), pointed: Bool = true,
        _ change: (inout InstalledRecord) -> Void = { _ in }
    ) async throws -> (Bool, [Message]) {
        var all = texts
        if pointed { all[pointer] = "/Users/test/dots\n" }
        let files = FakeFileSystem(
            items: ["/opt/homebrew/bin/brew": .file, "/opt/homebrew/bin/mas": .file], texts: all)
        let locks = FakeFileLocks()
        try InstalledRecord.change(in: StateFolder(files: files, locks: locks, paths: paths), change)
        var messages: [Message] = []
        let known = await StatusCommand(files: files, paths: paths, runner: runner, locks: locks).run {
            messages.append($0)
        }
        return (known, messages)
    }

    @Test func noDotsFolderIsAnError() async throws {
        let (known, messages) = try await status(pointed: false)
        #expect(!known)
        #expect(messages == [Message(.error, "couldn't show the status: no dots folder yet, run malum init")])
    }

    @Test func nothingManagedMatchesDots() async throws {
        let runner = FakeRunner()
        let (known, messages) = try await status(runner: runner)
        #expect(known)
        #expect(messages == [Message(.info, "everything Malum manages matches dots")])
        #expect(runner.commands.isEmpty)
    }

    @Test func packagesShowCountsAndWhatsOff() async throws {
        let list = "[homebrew]\nbat = \"formula\"\nfd = \"formula\"\n\n[app_store]\nXcode = 497799835\n"
        let runner = Self.runner(formulae: "bat\nwget\n", apps: "497799835  Xcode  (16.0)\n")
        let (known, messages) = try await status([packages: list], runner: runner) { record in
            record.formulae = ["bat", "wget"]
            record.appStore = ["Xcode": 497_799_835]
        }
        #expect(known)
        #expect(
            messages == [
                Message(.info, "managed Homebrew formulae: 2"),
                Message(.warn, "Homebrew formula fd isn't installed, malum run installs it"),
                Message(.warn, "Homebrew formula wget isn't listed anymore, malum run uninstalls it"),
                Message(.info, "managed App Store apps: 1"),
            ])
    }

    @Test func releasesMissingOrUnlistedAreReported() async throws {
        let list = "[release.zoxide]\nrepo = \"ajeetdsouza/zoxide\"\nasset = \"zoxide\"\n"
        let (known, messages) = try await status([packages: list]) { record in
            record.releases = ["eza": InstalledRelease(repo: "eza-community/eza", tag: "v1", path: "/Users/test/eza")]
        }
        #expect(known)
        #expect(
            messages == [
                Message(.info, "managed GitHub releases: 1"),
                Message(.warn, "GitHub release zoxide isn't installed, malum run installs it"),
                Message(.warn, "GitHub release eza isn't listed anymore, malum run uninstalls it"),
            ])
    }

    @Test func filesChangedOrMissingAreReported() async throws {
        let (known, messages) = try await status([kittyConf: "font_size 14\n", hosts: "127.0.0.1 localhost\n"]) {
            record in
            record.files = [
                kittyConf: ManagedFile(app: "kitty", text: "font_size 12\n"),
                "/Users/test/.config/micro/settings.json": ManagedFile(app: "micro", text: "{}\n"),
            ]
            record.systemFiles = [hosts: ManagedFile.fingerprint(of: "127.0.0.1 localhost\n")]
        }
        #expect(known)
        #expect(
            messages == [
                Message(.info, "managed app config files: 2"),
                Message(.warn, "\(kittyConf) was changed outside Malum, malum run overwrites it and keeps a .backup"),
                Message(.warn, "/Users/test/.config/micro/settings.json is missing, malum run writes it again"),
                Message(.info, "managed files only root can change: 1"),
            ])
    }

    @Test func preferencesAndPowerAreCounted() async throws {
        let runner = Self.runner(power: "Battery Power:\n lessbright 0\n displaysleep 5\n")
        let (known, messages) = try await status(runner: runner) { record in
            record.preferences = ["com.example.app": ManagedPreferences(app: "amphetamine", keys: ["one", "two"])]
            record.macOS = ["com.apple.dock": ManagedPreferences(app: "macos", keys: ["autohide"])]
            record.power = [
                "battery": [
                    "lessbright": ManagedPower(value: 1, original: 0),
                    "displaysleep": ManagedPower(value: 5, original: 2),
                ]
            ]
        }
        #expect(known)
        #expect(
            messages == [
                Message(.info, "managed app preferences: 2"),
                Message(.info, "managed macOS settings: 1"),
                Message(.info, "managed power settings: 2"),
                Message(.warn, "lessbright on battery power is 0, Malum set it to 1, malum run sets it back"),
            ])
    }

    @Test func badPackagesTomlIsAnError() async throws {
        let (known, messages) = try await status([packages: "[homebrew]\nbat = \"app\"\n"])
        #expect(!known)
        #expect(
            messages == [
                Message(.error, "packages.toml line 2: homebrew.bat should be \"formula\" or \"cask\""),
                Message(.error, "couldn't show the status: fix \(packages) first"),
            ])
    }
}
