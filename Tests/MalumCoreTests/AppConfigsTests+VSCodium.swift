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

            [settings]
            "update.mode" = "none"
            "editor.fontLigatures" = true

            [argv]
            enable-crash-reporter = false
            """, file: "apps/vscodium.toml")
        let read = config.read(&reader)
        #expect(reader.problems.isEmpty)
        #expect(read.extensions == ["dracula-theme.theme-dracula", "tamasfe.even-better-toml"])
        #expect(
            read.files == [
                AppFile(
                    "Library/Application Support/VSCodium/User/settings.json",
                    "{\n    \"editor.fontLigatures\": true,\n    \"update.mode\": \"none\"\n}\n"),
                AppFile(".vscode-oss/argv.json", "{\n    \"enable-crash-reporter\": false\n}\n"),
            ])
    }

    @Test func wrongExtensionsAreAnError() throws {
        let config = try #require(AppConfigs.app(named: "vscodium"))
        var reader = try TableReader("[extensions]\nids = [\"no-publisher\"]\nother = 1\n", file: "apps/vscodium.toml")
        let read = config.read(&reader)
        #expect(read.extensions.isEmpty)
        #expect(
            reader.problems.map { Message($0.level, $0.text) } == [
                Message(.warn, "unknown setting extensions.other"),
                Message(.error, "extensions.ids should be a list of extensions as \"publisher.name\""),
            ])
    }

    @Test func otherAppsHaveNoExtensions() throws {
        let (_, problems) = try read("[extensions]\nids = [\"a.b\"]\n")
        #expect(problems == [Message(.warn, "unknown table extensions")])
    }
}
