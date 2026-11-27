import Testing

@testable import MalumCore

/// Reading the hosts, sudo and power tables of macos.toml.
extension MacOSSettingsTests {
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
            screen_off_minutes = "never"
            [power.ups]
            dim_screen = false
            """)
        #expect(wanted == nil)
        #expect(
            problems.map(\.message) == [
                Message(
                    .error,
                    "macos.toml line 4: power.charger.screen_off_minutes should be a whole number of minutes, 0 or more"
                ),
                Message(.warn, "macos.toml line 5: unknown table power.ups"),
            ])
        #expect(
            MacOSSettings.read("[power.battery]\ndim_screen = true\n").wanted?.power == [.battery: ["lessbright": 1]])
    }

    @Test func pmsetNamesAreUnknown() {
        let (wanted, problems) = MacOSSettings.read("[power.battery]\nlessbright = 0\n")
        #expect(wanted == MacOSSettings.Wanted())
        #expect(
            problems.map(\.message) == [Message(.warn, "macos.toml line 2: unknown setting power.battery.lessbright")])
    }
}
