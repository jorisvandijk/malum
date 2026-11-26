import Testing

@testable import MalumCore

/// VSCodium's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    @Test func vscodiumWritesSettingsAndArgvAndListsExtensions() throws {
        let config = try #require(AppConfigs.app(named: "vscodium"))
        var reader = try TableReader(
            """
            [extensions]
            ids = ["dracula-theme.theme-dracula", "tamasfe.even-better-toml"]

            [appearance]
            theme = "Dracula Theme"

            [font]
            family = "Menlo"
            size_pt = 14
            ligatures = true

            [editor]
            auto_save = "after_delay"

            [updates]
            auto_check = false
            auto_check_extensions = false

            [privacy]
            telemetry = "off"
            send_crash_reports = false
            """, file: "apps/vscodium.toml")
        let read = config.read(&reader, home: "/Users/test")
        #expect(reader.problems.isEmpty)
        #expect(read.extensions == ["dracula-theme.theme-dracula", "tamasfe.even-better-toml"])
        #expect(
            read.files == [
                AppFile(
                    "Library/Application Support/VSCodium/User/settings.json",
                    "{\n    \"editor.fontFamily\": \"'Menlo', monospace\",\n    \"editor.fontLigatures\": true,\n"
                        + "    \"editor.fontSize\": 14,\n    \"extensions.autoCheckUpdates\": false,\n"
                        + "    \"files.autoSave\": \"afterDelay\",\n    \"telemetry.telemetryLevel\": \"off\",\n"
                        + "    \"terminal.integrated.fontFamily\": \"'Menlo', monospace\",\n"
                        + "    \"terminal.integrated.fontSize\": 14,\n    \"update.mode\": \"none\",\n"
                        + "    \"workbench.colorTheme\": \"Dracula Theme\"\n}\n"),
                AppFile(".vscode-oss/argv.json", "{\n    \"enable-crash-reporter\": false\n}\n"),
            ])
    }

    @Test func vscodiumTakesNoRawSettings() throws {
        let config = try #require(AppConfigs.app(named: "vscodium"))
        var reader = try TableReader(
            "[settings]\n\"update.mode\" = \"none\"\n\n[updates]\nauto_check = true\n", file: "apps/vscodium.toml")
        let read = config.read(&reader, home: "/Users/test")
        #expect(reader.problems.map { Message($0.level, $0.text) } == [Message(.warn, "unknown table settings")])
        #expect(read.files.first?.text == "{\n    \"update.mode\": \"default\"\n}\n")
    }

    @Test func wrongExtensionsAreAnError() throws {
        let config = try #require(AppConfigs.app(named: "vscodium"))
        var reader = try TableReader("[extensions]\nids = [\"no-publisher\"]\nother = 1\n", file: "apps/vscodium.toml")
        let read = config.read(&reader, home: "/Users/test")
        #expect(read.extensions.isEmpty)
        #expect(
            reader.problems.map { Message($0.level, $0.text) } == [
                Message(.warn, "unknown setting extensions.other"),
                Message(.error, "extensions.ids should be a list of extensions as \"publisher.name\""),
            ])
    }

    @Test func otherAppsHaveNoExtensions() throws {
        let (_, problems) = try read("[extensions]\nids = [\"a.b\"]\n", app: "git")
        #expect(problems == [Message(.warn, "unknown table extensions")])
    }
}
