import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct MacOSSettingsTests {
    private let paths = Paths(home: "/Users/test")
    private let file = "/Users/test/dots/macos.toml"

    /// The window tiling preferences Malum always turns off, as plist elements, already off.
    nonisolated private static let tilingOff = """
        <key>EnableTilingByEdgeDrag</key><false/><key>EnableTopTilingByEdgeDrag</key><false/>\
        <key>EnableTilingOptionAccelerator</key><false/>
        """

    /// An export holding `entries`, plist elements keyed by name, and the tiling preferences, off.
    nonisolated private static func export(_ entries: String = "") -> CommandResult {
        CommandResult(status: 0, output: "<plist version=\"1.0\"><dict>\(tilingOff)\(entries)</dict></plist>")
    }

    /// Runs the part on `files` with `runner`, and gives back whether it worked and what it said.
    private func run(_ files: FakeFileSystem, runner: FakeRunner) async -> (Bool, [Message]) {
        var messages: [Message] = []
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        let sudo = SudoSession(runner: runner, canAsk: true)
        let succeeded = await MacOSSettings(
            files: files, runner: runner, sudo: sudo, state: state, paths: paths, handlers: FakeAppHandlers(),
            display: FakeDisplay()
        ).run(dots: "/Users/test/dots") { messages.append($0) }
        return (succeeded, messages)
    }

    private func record(_ files: FakeFileSystem) -> InstalledRecord {
        let state = StateFolder(files: files, locks: FakeFileLocks(), paths: paths)
        return (try? InstalledRecord.read(from: state)) ?? InstalledRecord()
    }

    @Test func rawDomainsStillWorkWithAWarning() {
        let (wanted, problems) = MacOSSettings.read(
            """
            [preferences.NSGlobalDomain]
            KeyRepeat = 2
            [preferences."com.apple.finder"]
            ShowPathbar = true
            [current_host."com.apple.controlcenter"]
            Timer = 8
            """)
        let raw = "is a raw macOS preference, which stops working in the next release:"
        #expect(
            problems.map(\.message) == [
                Message(
                    .warn,
                    "macos.toml line 2: preferences.NSGlobalDomain.KeyRepeat \(raw) use keyboard.repeat_interval_ms instead"
                ),
                Message(
                    .warn,
                    "macos.toml line 4: preferences.\"com.apple.finder\".ShowPathbar \(raw) use finder.show_path_bar instead"
                ),
                Message(
                    .warn,
                    "macos.toml line 6: current_host.\"com.apple.controlcenter\".Timer \(raw) use menu_bar.show_timer instead"
                ),
            ])
        #expect(
            wanted?.preferences.map { "\($0.domain) \($0.key)" } == [
                "NSGlobalDomain KeyRepeat", "com.apple.finder ShowPathbar",
                "com.apple.controlcenter (current host) Timer",
            ])
    }

    @Test func rawPreferenceWithoutACuratedNameSaysSo() {
        let (_, problems) = MacOSSettings.read("[preferences.\"com.apple.dock\"]\nmineffect = \"scale\"\n")
        #expect(
            problems.map(\.message) == [
                Message(
                    .warn,
                    """
                    macos.toml line 2: preferences."com.apple.dock".mineffect is a raw macOS preference, which stops \
                    working in the next release: it has no curated name yet, see docs/macos-settings.md
                    """)
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
            dim_screen = false
            [power.charger]
            screen_off_min = "never"
            [power.ups]
            dim_screen = false
            """)
        #expect(wanted == nil)
        #expect(
            problems.map(\.message) == [
                Message(
                    .error,
                    "macos.toml line 4: power.charger.screen_off_min should be a whole number of minutes, 0 for never"),
                Message(.warn, "macos.toml line 5: unknown table power.ups"),
            ])
        #expect(
            MacOSSettings.read("[power.battery]\ndim_screen = true\n").wanted?.power == [.battery: ["lessbright": 1]])
    }

    @Test func rawAndCuratedPowerNamesClashing() {
        let (wanted, problems) = MacOSSettings.read("[power.battery]\nsleep_min = 5\nsleep = 10\n")
        #expect(wanted == nil)
        #expect(
            problems.map(\.message).contains(
                Message(
                    .error,
                    "macos.toml line 2: power.battery.sleep_min sets the same macOS setting as power.battery.sleep, to something else"
                )))
    }

    @Test func rawPowerNamesStillWorkWithAWarning() {
        let (wanted, problems) = MacOSSettings.read("[power.battery]\nlessbright = 0\n")
        #expect(wanted?.power == [.battery: ["lessbright": 0]])
        #expect(
            problems.map(\.message) == [
                Message(
                    .warn,
                    """
                    macos.toml line 2: power.battery.lessbright is a raw pmset name, which stops working in the next \
                    release: use power.battery.dim_screen instead
                    """)
            ])
    }

    @Test func unknownTableIsAWarning() {
        let (wanted, problems) = MacOSSettings.read("[docks]\nautohide = true\n")
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
                [keyboard]
                repeat_interval_ms = 30
                [finder]
                show_path_bar = true
                [menu_bar]
                show_timer = false
                """
            ])
        let (succeeded, messages) = await run(files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands.contains(ActivateSettings.user))
        #expect(
            runner.commands.contains(
                Defaults.write("NSGlobalDomain", "KeyRepeat", PlistText.document(.integer(2)) ?? "")))
        #expect(runner.commands.suffix(2) == [Killall.restart("ControlCenter"), Killall.restart("Finder")])
        #expect(
            messages == [
                Message(.info, "set keyboard.repeat_interval_ms in NSGlobalDomain from macos.toml"),
                Message(.info, "set menu_bar.show_timer in com.apple.controlcenter (current host) from macos.toml"),
                Message(.info, "set finder.show_path_bar in com.apple.finder from macos.toml"),
                Message(.info, "restarted ControlCenter to use the new settings"),
                Message(.info, "restarted Finder to use the new settings"),
                Message(
                    .info, "some macOS settings, such as key repeat, take full effect after you log out and back in"),
            ])
        #expect(record(files).macOS["com.apple.finder"] == ManagedPreferences(app: "macos.toml", keys: ["ShowPathbar"]))
        #expect(record(files).preferences.isEmpty)
    }

    @Test func windowTilingIsAlwaysTurnedOff() async {
        let runner = FakeRunner { _ in CommandResult(status: 0, output: "<plist version=\"1.0\"><dict></dict></plist>")
        }
        let files = FakeFileSystem(texts: [file: "[computer]\n"])
        let (succeeded, _) = await run(files, runner: runner)
        let off = PlistText.document(.boolean(false)) ?? ""
        #expect(succeeded)
        #expect(
            MacOSCatalog.alwaysSet.map(\.target.key).allSatisfy {
                runner.commands.contains(Defaults.write("com.apple.WindowManager", $0, off))
            })
    }

    @Test func turningWindowTilingOnIsAnError() {
        let (wanted, problems) = MacOSSettings.read(
            "[preferences.\"com.apple.WindowManager\"]\nEnableTilingByEdgeDrag = true\n")
        #expect(wanted == nil)
        #expect(
            problems.map(\.message).last
                == Message(
                    .error,
                    """
                    macos.toml line 2: preferences."com.apple.WindowManager".EnableTilingByEdgeDrag can't be set: \
                    Malum always turns macOS's window tiling off, its window manager tiles
                    """))
    }

    @Test func dockAppsWithKeysMacOSAddedAreUpToDate() async {
        let apps = """
            <key>persistent-apps</key><array><dict><key>GUID</key><integer>42</integer><key>tile-data</key><dict>\
            <key>file-data</key><dict><key>_CFURLString</key><string>file:///Applications/Safari.app/</string>\
            <key>_CFURLStringType</key><integer>15</integer></dict><key>bundle-identifier</key>\
            <string>com.apple.Safari</string></dict><key>tile-type</key><string>file-tile</string></dict></array>
            """
        let runner = FakeRunner { _ in Self.export(apps) }
        let files = FakeFileSystem(texts: [file: "[dock]\npinned_apps = [\"/Applications/Safari.app\"]\n"])
        let (succeeded, messages) = await run(files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Defaults.export("com.apple.WindowManager"), Defaults.export("com.apple.dock")])
        #expect(messages == [Message(.info, "every macOS setting is up to date")])
    }

    @Test func curatedTablesInDotsReadWithoutProblems() {
        let (wanted, problems) = MacOSSettings.read(
            """
            [appearance]
            mode = "dark"
            accent_color = "pink"
            [menu_bar]
            hide = "always"
            show_spotlight = false
            [pointer]
            natural_scrolling = false
            [keyboard]
            repeat_delay_ms = 450
            repeat_interval_ms = 30
            input_sources = ["us"]
            [finder]
            view = "list"
            new_window = "home"
            [dock]
            show = "never"
            pinned_apps = []
            pinned_folders = []
            [siri]
            enabled = false
            [power.battery]
            dim_screen = false
            """)
        #expect(problems.isEmpty)
        #expect(wanted?.preferences.isEmpty == false)
    }

    @Test func appsThatArentRunningAreNotRestarted() async {
        let runner = FakeRunner { command in
            command == Killall.restart("Finder")
                ? CommandResult(status: 1, errors: "No matching processes belonging to you were found")
                : Self.export()
        }
        let files = FakeFileSystem(texts: [file: "[finder]\nshow_path_bar = true\n"])
        let (succeeded, messages) = await run(files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands.last == Killall.restart("Finder"))
        #expect(messages == [Message(.info, "set finder.show_path_bar in com.apple.finder from macos.toml")])
    }

    @Test func settingsAlreadySetRestartNothing() async {
        let runner = FakeRunner { _ in Self.export("<key>autohide</key><true/>") }
        let files = FakeFileSystem(texts: [file: "[dock]\nshow = \"auto_hide\"\n"])
        let (succeeded, messages) = await run(files, runner: runner)
        #expect(succeeded)
        #expect(runner.commands == [Defaults.export("com.apple.WindowManager"), Defaults.export("com.apple.dock")])
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
