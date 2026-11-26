import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct MacOSCatalogTests {
    /// The preferences `toml` asks for, as `domain key = value`, with `-` for one that has to be
    /// absent, and the problems found.
    func read(_ toml: String) -> (preferences: [String], problems: [Message]) {
        let (wanted, problems) = MacOSSettings.read(toml)
        let preferences = (wanted?.preferences ?? []).map { preference in
            "\(preference.domain) \(preference.key) = \(preference.value.map(Self.element) ?? "-")"
        }
        return (preferences, problems.map(\.message))
    }

    /// The one element in `document`, a property list document.
    private static func element(_ document: String) -> String {
        let start = document.range(of: "<plist version=\"1.0\">")?.upperBound ?? document.startIndex
        let end = document.range(of: "</plist>")?.lowerBound ?? document.endIndex
        return String(document[start..<end])
    }

    @Test func everySettingTakesAtLeastTwoValues() {
        for table in MacOSCatalog.tables {
            for setting in table.settings {
                #expect((setting.value.choices ?? 2) >= 2, "\(table.name).\(setting.name)")
            }
        }
    }

    @Test func everyChoiceWritesEachTarget() {
        for setting in MacOSCatalog.tables.flatMap(\.settings) {
            switch setting.value {
            case .choice(let choices):
                #expect(choices.allSatisfy { $0.writes.count == setting.targets.count }, "\(setting.name)")
                #expect(Set(choices.map(\.word)).count == choices.count, "\(setting.name)")
            case .combinedFlag(let on, let off):
                #expect(on.count == setting.targets.count && off.count == setting.targets.count, "\(setting.name)")
            default:
                #expect(!setting.targets.isEmpty, "\(setting.name)")
            }
        }
    }

    @Test func namesAreUniqueAndPlain() {
        let tables = MacOSCatalog.tables.map(\.name)
        #expect(Set(tables).count == tables.count)
        for table in MacOSCatalog.tables {
            let names = table.settings.map(\.name)
            #expect(Set(names).count == names.count, "\(table.name)")
            #expect(
                (names + [table.name]).allSatisfy { $0.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" } })
        }
        #expect(Set(PowerSetting.all.map(\.name)).count == PowerSetting.all.count)
    }

    @Test func noTwoSettingsWriteTheSamePreferenceExceptSiri() {
        var writers: [String: [String]] = [:]
        for table in MacOSCatalog.tables {
            for setting in table.settings {
                for target in setting.targets {
                    writers["\(target)", default: []].append("\(table.name).\(setting.name)")
                }
            }
        }
        let shared = writers.values.filter { $0.count > 1 }.flatMap { $0 }
        #expect(Set(shared) == ["siri.enabled", "siri.listen", "siri.show_in_menu_bar"])
    }

    @Test func switchesWriteTrueOrFalseOrTheirNumbers() {
        let (preferences, problems) = read(
            """
            [pointer]
            natural_scrolling = false
            shake_to_locate = false
            [menu_bar]
            show_spotlight = false
            show_timer = true
            """)
        #expect(problems.isEmpty)
        #expect(
            preferences == [
                "com.apple.Spotlight (current host) MenuItemHidden = <integer>1</integer>",
                "com.apple.controlcenter (current host) Timer = <integer>18</integer>",
                "NSGlobalDomain com.apple.swipescrolldirection = <false/>",
                "NSGlobalDomain CGDisableCursorLocationMagnification = <true/>",
            ])
    }

    @Test func oneSettingCanWriteSeveralPreferences() {
        let (preferences, _) = read("[trackpad]\ntap_to_click = true\n[text]\nauto_correct = false\n")
        #expect(
            preferences == [
                "com.apple.AppleMultitouchTrackpad Clicking = <true/>",
                "com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking = <true/>",
                "NSGlobalDomain NSAutomaticSpellingCorrectionEnabled = <false/>",
                "NSGlobalDomain WebAutomaticSpellingCorrectionEnabled = <false/>",
            ])
    }

    @Test func choicesWriteTheirValuesAndRemoveSome() {
        let (preferences, problems) = read(
            """
            [appearance]
            mode = "light"
            accent_color = "pink"
            [finder]
            view = "list"
            [menu_bar]
            hide = "always"
            [dock]
            show = "never"
            """)
        #expect(problems.isEmpty)
        #expect(
            preferences == [
                "NSGlobalDomain AppleInterfaceStyle = -",
                "NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically = -",
                "NSGlobalDomain AppleAccentColor = <integer>6</integer>",
                "NSGlobalDomain _HIHideMenuBar = <true/>",
                "NSGlobalDomain AppleMenuBarVisibleInFullscreen = <false/>",
                "com.apple.finder FXPreferredViewStyle = <string>Nlsv</string>",
                "com.apple.dock autohide = <true/>",
                "com.apple.dock autohide-delay = <real>1000.0</real>",
                "com.apple.dock autohide-time-modifier = <real>0.0</real>",
            ])
    }

    @Test func autoModeLeavesTheStyleToMacOS() {
        let (preferences, problems) = read("[appearance]\nmode = \"auto\"\n")
        #expect(problems.isEmpty)
        #expect(preferences == ["NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically = <true/>"])
    }

    @Test func keyboardNeedsALayoutButTheDockCanBeEmpty() {
        let (_, problems) = read("[keyboard]\ninput_sources = []\n[dock]\npinned_apps = []\n")
        #expect(problems.map(\.level) == [.error])
        #expect(
            problems.first?.text.description.hasPrefix("macos.toml line 2: keyboard.input_sources should be") == true)
    }

    @Test func numbersAreTranslated() {
        let (preferences, problems) = read(
            "[keyboard]\nrepeat_delay_ms = 450\nrepeat_interval_ms = 35\n[sound]\nalert_volume = 50\n")
        #expect(problems.isEmpty)
        #expect(
            preferences == [
                "NSGlobalDomain com.apple.sound.beep.volume = <real>0.5</real>",
                "NSGlobalDomain InitialKeyRepeat = <integer>30</integer>",
                "NSGlobalDomain KeyRepeat = <integer>2</integer>",
            ])
    }

    @Test func listsAreWrittenAsMacOSKeepsThem() {
        let (preferences, problems) = read(
            """
            [keyboard]
            input_sources = ["us"]
            [dock]
            pinned_apps = ["/Applications/Safari.app"]
            pinned_folders = []
            """)
        #expect(problems.isEmpty)
        #expect(
            preferences == [
                """
                com.apple.HIToolbox AppleEnabledInputSources = <array><dict><key>InputSourceKind</key>\
                <string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>0</integer>\
                <key>KeyboardLayout Name</key><string>U.S.</string></dict></array>
                """,
                """
                com.apple.dock persistent-apps = <array><dict><key>tile-data</key><dict><key>file-data</key><dict>\
                <key>_CFURLString</key><string>file:///Applications/Safari.app/</string>\
                <key>_CFURLStringType</key><integer>15</integer></dict></dict>\
                <key>tile-type</key><string>file-tile</string></dict></array>
                """,
                "com.apple.dock persistent-others = <array></array>",
            ])
    }

    @Test func siriOffTurnsEverythingOffAndClashesWithListening() {
        let (preferences, problems) = read("[siri]\nenabled = false\n")
        #expect(problems.isEmpty)
        #expect(
            preferences == [
                "com.apple.assistant.support Assistant Enabled = <false/>",
                "com.apple.Siri VoiceTriggerUserEnabled = <false/>",
                "com.apple.Siri StatusMenuVisible = <false/>",
            ])
        let clash = read("[siri]\nenabled = false\nlisten = true\n")
        #expect(
            clash.problems == [
                Message(
                    .error,
                    "macos.toml line 3: siri.listen sets the same setting as siri.enabled, to something else")
            ])
    }

    @Test func rawAndCuratedSettingClashing() {
        let (_, problems) = read(
            "[pointer]\nnatural_scrolling = true\n[preferences.NSGlobalDomain]\n\"com.apple.swipescrolldirection\" = false\n"
        )
        #expect(
            problems.last
                == Message(
                    .error,
                    """
                    macos.toml line 4: preferences.NSGlobalDomain."com.apple.swipescrolldirection" sets the same \
                    setting as pointer.natural_scrolling, to something else
                    """))
    }

    @Test func wrongValuesSayWhatTheyShouldBe() {
        let (_, problems) = read(
            """
            [appearance]
            mode = "grey"
            [keyboard]
            repeat_delay_ms = 5
            input_sources = ["klingon"]
            [screen_capture]
            folder = "~/Pictures"
            [trackpad]
            force_touch = false
            """)
        #expect(
            problems == [
                Message(.error, "macos.toml line 2: appearance.mode should be \"light\", \"dark\" or \"auto\""),
                Message(
                    .error,
                    "macos.toml line 4: keyboard.repeat_delay_ms should be milliseconds from 15 to 1800, in steps of 15"
                ),
                Message(
                    .error,
                    """
                    macos.toml line 5: keyboard.input_sources should be a list of at least one keyboard layout, each "us", \
                    "us_international", "abc", "british", "dutch", "german", "french", "dvorak" or "colemak"
                    """),
                Message(
                    .error, "macos.toml line 7: screen_capture.folder should be a folder's full path, starting with /"),
                Message(.warn, "macos.toml line 9: unknown setting trackpad.force_touch"),
            ])
    }

    @Test func docsListEveryTableAndSetting() {
        let page = MacOSDocs.page()
        for table in MacOSCatalog.tables {
            #expect(page.contains("\n## `[\(table.name)]`\n"))
            for setting in table.settings {
                #expect(page.contains("### `\(setting.name)`"), "\(table.name).\(setting.name)")
            }
        }
        #expect(PowerSetting.all.allSatisfy { page.contains("- Writes: `pmset` `\($0.pmset)`") })
        #expect(page.contains("- Writes: `NSGlobalDomain` `com.apple.swipescrolldirection`"))
    }
}
