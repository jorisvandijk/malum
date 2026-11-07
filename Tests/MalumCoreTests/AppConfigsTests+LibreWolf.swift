import Testing

@testable import MalumCore

/// LibreWolf's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    private static let libreWolf = "Library/Application Support/LibreWolf"

    @Test func libreWolfWritesItsProfile() throws {
        let (files, problems) = try read(
            #"""
            [settings]
            "sidebar.verticalTabs" = true
            "browser.startup.page" = 3
            "browser.startup.homepage" = "https://example.com/\"a\""

            [user_chrome]
            text = '''
            #alltabs-button { display: none !important; }
            '''
            """#, app: "librewolf")
        let note = "Written by Malum from apps/librewolf.toml in dots. Changes made here are overwritten."
        #expect(problems.isEmpty)
        #expect(files.map(\.path).first == "\(Self.libreWolf)/profiles.ini")
        #expect(files.first?.onlyWhenMissing == true)
        #expect(files.first?.text.hasPrefix("[General]\nStartWithLastProfile=1\n\n[Profile0]\nDefault=1\n") == true)
        #expect(
            files.dropFirst() == [
                AppFile(
                    "\(Self.libreWolf)/Profiles/default/user.js",
                    "// \(note)\n" + #"user_pref("browser.startup.homepage", "https://example.com/\"a\"");"# + "\n"
                        + "user_pref(\"browser.startup.page\", 3);\nuser_pref(\"sidebar.verticalTabs\", true);\n"),
                AppFile(
                    "\(Self.libreWolf)/Profiles/default/chrome/userChrome.css",
                    "/* \(note) */\n#alltabs-button { display: none !important; }\n"),
            ])
    }

    @Test func libreWolfWithNothingWritesOnlyItsProfileList() throws {
        let (files, problems) = try read("", app: "librewolf")
        #expect(problems.isEmpty)
        #expect(files.map(\.path) == ["\(Self.libreWolf)/profiles.ini"])
    }

    @Test func libreWolfSettingThatIsAListIsAnError() throws {
        let (files, problems) = try read("[settings]\nlist = [1]\n", app: "librewolf")
        #expect(files.count == 1)
        #expect(problems == [Message(.error, "settings.list should be text, a number, or true or false")])
    }

    @Test func libreWolfPoliciesAreSystemWidePreferences() throws {
        let config = try #require(AppConfigs.app(named: "librewolf"))
        var reader = try TableReader(
            """
            [policies]
            DisableTelemetry = true

            [policies.ExtensionSettings."uBlock0@raymondhill.net"]
            installation_mode = "force_installed"
            """, file: "apps/librewolf.toml")
        let read = config.read(&reader)
        #expect(reader.problems.isEmpty)
        #expect(read.preferences.map(\.key) == ["DisableTelemetry", "ExtensionSettings"])
        #expect(read.preferences.allSatisfy { $0.domain == "/Library/Preferences/net.librewolf.librewolf" })
        #expect(read.preferences.last?.value.contains("<key>uBlock0@raymondhill.net</key><dict>") == true)
    }
}
