import Testing

@testable import MalumCore

/// The apps whose preferences system config sets, each through its catalog.
extension AppConfigsTests {
    /// The preferences the app `name` gets from `toml`, as `key = value` with the value's one
    /// property list element, and the problems found.
    private func preferences(_ name: String, _ toml: String) throws -> (preferences: [String], problems: [Message]) {
        let config = try #require(AppConfigs.app(named: name))
        var reader = try TableReader(toml, file: Paths.appFile(named: name))
        let read = config.read(&reader, home: "/Users/test")
        #expect(read.files.isEmpty)
        #expect(read.preferences.allSatisfy { $0.domain == config.domain })
        let preferences = read.preferences.map { "\($0.key) = \(Self.element($0.value ?? ""))" }
        return (preferences, reader.problems.map { Message($0.level, $0.text) })
    }

    /// The one element in the property list `document`, with the space between elements taken out.
    private static func element(_ document: String) -> String {
        let start = document.range(of: "<plist version=\"1.0\">")?.upperBound ?? document.startIndex
        let end = document.range(of: "</plist>")?.lowerBound ?? document.endIndex
        return document[start..<end].split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.joined()
    }

    @Test func amphetamineSettingsWriteItsPreferences() throws {
        let (preferences, problems) = try preferences(
            "amphetamine",
            """
            [appearance]
            show_dock_icon = false
            [sessions]
            allow_display_sleep = false
            allow_sleep_when_closed = true
            allow_screen_saver = false
            move_pointer = false
            [statistics]
            enabled = true
            """)
        #expect(problems.isEmpty)
        #expect(
            preferences == [
                "Icon Style = <integer>0</integer>", "Default Duration = <integer>0</integer>",
                "Hide Dock Icon = <true/>", "Allow Display Sleep = <false/>", "Allow Closed-Display Sleep = <true/>",
                "Allow Screen Saver = <false/>", "Enable Mouse Movement = <false/>", "Enable Statistics = <true/>",
            ])
    }

    @Test func commandXShortcutsAreCarbonJSON() throws {
        let (preferences, problems) = try preferences(
            "command-x", "[shortcuts]\ncut = \"cmd+x\"\npaste = \"cmd+v\"\n")
        #expect(problems.isEmpty)
        #expect(
            preferences == [
                "newMethod = <true/>",
                "KeyboardShortcuts_cut = <string>{\"carbonKeyCode\":7,\"carbonModifiers\":256}</string>",
                "KeyboardShortcuts_paste = <string>{\"carbonKeyCode\":9,\"carbonModifiers\":256}</string>",
            ])
    }

    @Test func cursorcererShortcutIsACarbonTable() throws {
        let (preferences, problems) = try preferences(
            "cursorcerer",
            "[shortcuts]\ntoggle_pointer = \"ctrl+option+k\"\n[pointer]\nhide_after_seconds = 5\nshow_on_move = true\n")
        #expect(problems.isEmpty)
        #expect(
            preferences == [
                "toggleCursorHotKey = <dict><key>keyCode</key><integer>40</integer><key>modifiers</key><integer>6144</integer></dict>",
                "idleHide = <integer>5</integer>", "autoShow = <true/>",
            ])
    }

    @Test func oversightSettingsWriteItsPreferences() throws {
        let (preferences, problems) = try preferences(
            "oversight", "[startup]\nat_login = true\n[updates]\nauto_check = false\n")
        #expect(problems.isEmpty)
        #expect(preferences == ["startAtLogin = <true/>", "noupdateMode = <true/>"])
    }

    @Test func rawPreferencesAndWrongValuesAreProblems() throws {
        let (preferences, problems) = try preferences(
            "cursorcerer",
            "[preferences]\nidleHide = 5\n[shortcuts]\ntoggle_pointer = \"fn+k\"\n[pointer]\nhide_after_seconds = 0\n")
        #expect(preferences.isEmpty)
        #expect(problems.map(\.level) == [.warn, .error, .error])
        #expect(problems.first?.text.description.contains("preferences") == true)
    }
}
