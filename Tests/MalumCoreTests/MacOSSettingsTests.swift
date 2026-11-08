import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct MacOSSettingsTests {
    private let paths = Paths(home: "/Users/test")
    private let file = "/Users/test/dots/macos.toml"

    /// An export holding `entries`, plist elements keyed by name.
    nonisolated private static func export(_ entries: String = "") -> CommandResult {
        CommandResult(status: 0, output: "<plist version=\"1.0\"><dict>\(entries)</dict></plist>")
    }

    /// Runs the part on `files` with `runner`, and gives back whether it worked and what it said.
    private func run(_ files: FakeFileSystem, runner: FakeRunner) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        let sudo = SudoSession(runner: runner, canAsk: true)
        let succeeded = await MacOSSettings(
            files: files, runner: runner, sudo: sudo, state: state, paths: paths, handlers: FakeAppHandlers()
        ).run(dots: "/Users/test/dots") { messages.append($0) }
        return (succeeded, messages)
    }

    private func record(_ files: FakeFileSystem) -> InstalledRecord {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        return (try? InstalledRecord.read(from: state)) ?? InstalledRecord()
    }

    @Test func readsEachDomainAndTheCurrentHostOnes() {
        let (wanted, problems) = MacOSSettings.read(
            """
            [preferences.NSGlobalDomain]
            KeyRepeat = 2
            [preferences."com.apple.finder"]
            ShowPathbar = true
            [current_host."com.apple.controlcenter"]
            Timer = 8
            """)
        #expect(problems.isEmpty)
        #expect(
            wanted?.preferences.map { "\($0.domain) \($0.key)" } == [
                "NSGlobalDomain KeyRepeat", "com.apple.finder ShowPathbar",
                "com.apple.controlcenter (current host) Timer",
            ])
    }

    @Test func badDomainsAreErrors() {
        let (wanted, problems) = MacOSSettings.read(
            """
            [preferences."-g"]
            KeyRepeat = 2
            [preferences]
            NSGlobalDomain = 2
            """)
        #expect(wanted == nil)
        #expect(
            problems.map(\.message) == [
                Message(.error, "macos.toml line 1: preferences.-g: a preferences domain can't start with -"),
                Message(.error, "macos.toml line 4: preferences.NSGlobalDomain should be a table"),
            ])
    }

    @Test func readsHostsAndTouchID() {
        let (wanted, problems) = MacOSSettings.read(
            """
            [hosts]
            "nas.home" = "10.0.0.2"
            "ha.home" = "10.0.0.3"
            [sudo]
            touch_id = true
            """)
        #expect(problems.isEmpty)
        #expect(wanted?.files[SystemFile.sudoLocal.path] == SystemFile.touchID)
        #expect(
            wanted?.files[SystemFile.hosts.path]?.hasSuffix(
                "::1             localhost\n\n10.0.0.3\tha.home\n10.0.0.2\tnas.home\n") == true)
    }

    @Test func touchIDOffAndNoHostsWriteNothing() {
        let (wanted, problems) = MacOSSettings.read("[sudo]\ntouch_id = false\n")
        #expect(problems.isEmpty)
        #expect(wanted == MacOSSettings.Wanted())
    }

    @Test func emptyHostsKeepsOnlyMacOSLines() {
        let (wanted, _) = MacOSSettings.read("[hosts]\n")
        #expect(wanted?.files[SystemFile.hosts.path]?.hasSuffix("::1             localhost\n") == true)
    }

    @Test func badHostsAndSudoAreErrors() {
        let (wanted, problems) = MacOSSettings.read(
            """
            [hosts]
            "nas home" = "10.0.0.2"
            printer = 3
            [sudo]
            touch_id = "yes"
            face_id = true
            """)
        #expect(wanted == nil)
        #expect(
            problems.map(\.message) == [
                Message(
                    .error,
                    "macos.toml line 2: hosts.\"nas home\": a host name and its address can't be empty or hold spaces"),
                Message(.error, "macos.toml line 3: hosts.printer should be text in quotes"),
                Message(.error, "macos.toml line 5: sudo.touch_id should be true or false"),
                Message(.warn, "macos.toml line 6: unknown setting sudo.face_id"),
            ])
    }

    @Test func readsPowerBySource() {
        let (wanted, problems) = MacOSSettings.read(
            """
            [power.battery]
            lessbright = 0
            [power.charger]
            displaysleep = "never"
            [power.ups]
            lessbright = 0
            """)
        #expect(wanted == nil)
        #expect(
            problems.map(\.message) == [
                Message(.error, "macos.toml line 4: power.charger.displaysleep should be a whole number"),
                Message(.warn, "macos.toml line 5: unknown table power.ups"),
            ])
        #expect(MacOSSettings.read("[power.battery]\nlessbright = 0\n").wanted?.power == [.battery: ["lessbright": 0]])
    }

    @Test func unknownTableIsAWarning() {
        let (wanted, problems) = MacOSSettings.read("[dock]\nautohide = true\n")
        #expect(wanted == MacOSSettings.Wanted())
        #expect(problems.map(\.message.level) == [.warn])
    }

    @Test func missingFileTouchesNothing() async {
        let runner = FakeRunner()
        let (succeeded, messages) = await run(FakeFileSystem(), runner: runner)
        #expect(succeeded)
        #expect(runner.commands.isEmpty)
        #expect(messages == [Message(.info, "no macOS settings to set: \(file) doesn't exist")])
    }

    @Test func brokenFileTouchesNothing() async {
        let runner = FakeRunner()
        let files = FakeFileSystem(texts: [file: "[preferences.\"com.apple.dock\"]\nautohide = 1979-05-27\n"])
        let (succeeded, messages) = await run(files, runner: runner)
        #expect(!succeeded)
        #expect(runner.commands.isEmpty)
        #expect(messages.last == Message(.error, "couldn't set macOS settings: fix \(file) first"))
        #expect(messages.first?.text.description.hasPrefix("macos.toml line 2: ") == true)
    }

    @Test func changedSettingsAreShownAndRecorded() async {
        let runner = FakeRunner { _ in Self.export() }
        let files = FakeFileSystem(
            texts: [
                file: """
                [preferences.NSGlobalDomain]
                KeyRepeat = 2
                [preferences."com.apple.finder"]
                ShowPathbar = true
                [current_host."com.apple.controlcenter"]
                Timer = 8
                """
            ])
        let (succeeded, messages) = await run(files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands.contains(ActivateSettings.user))
        #expect(runner.commands.suffix(2) == [Killall.restart("ControlCenter"), Killall.restart("Finder")])
        #expect(
            messages == [
                Message(.info, "set KeyRepeat in NSGlobalDomain from macos.toml"),
                Message(.info, "set Timer in com.apple.controlcenter (current host) from macos.toml"),
                Message(.info, "set ShowPathbar in com.apple.finder from macos.toml"),
                Message(.info, "restarted ControlCenter to use the new settings"),
                Message(.info, "restarted Finder to use the new settings"),
                Message(
                    .info, "some macOS settings, such as key repeat, take full effect after you log out and back in"),
            ])
        #expect(record(files).macOS["com.apple.finder"] == ManagedPreferences(app: "macos.toml", keys: ["ShowPathbar"]))
        #expect(record(files).preferences.isEmpty)
    }

    @Test func settingsAlreadySetRestartNothing() async {
        let runner = FakeRunner { _ in Self.export("<key>autohide</key><true/>") }
        let files = FakeFileSystem(texts: [file: "[preferences.\"com.apple.dock\"]\nautohide = true\n"])
        let (succeeded, messages) = await run(files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Defaults.export("com.apple.dock")])
        #expect(messages == [Message(.info, "every macOS setting is up to date")])
    }

    @Test func currentHostDomainsUseTheFlag() {
        let domain = Defaults.currentHost("com.apple.controlcenter")
        #expect(Defaults.export(domain).arguments == ["-currentHost", "export", "com.apple.controlcenter", "-"])
        #expect(
            Defaults.delete(domain, "Timer").arguments == [
                "-currentHost", "delete", "com.apple.controlcenter", "Timer",
            ])
        #expect(Defaults.delete("com.apple.dock", "autohide").arguments == ["delete", "com.apple.dock", "autohide"])
    }
}
