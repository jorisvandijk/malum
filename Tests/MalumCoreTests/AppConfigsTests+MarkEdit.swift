import Foundation
import Testing

@testable import MalumCore

/// MarkEdit's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    /// Where MarkEdit reads its settings file and CSS, relative to home.
    private static let markEditDocuments = "Library/Containers/app.cyan.markedit/Data/Documents"

    @Test func markEditWritesItsSettingsFileAndCSS() throws {
        let (files, problems) = try read(
            """
            [updates]
            auto_check = false

            [css]
            text = ".cm-md-codeBlock { font-family: Menlo !important; }"
            """, app: "markedit")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    "\(Self.markEditDocuments)/settings.json", "{\n    \"general.updateBehavior\": \"never\"\n}\n"),
                AppFile(
                    "\(Self.markEditDocuments)/editor.css",
                    "/* Written by Malum from apps/markedit.toml in dots. Changes made here are overwritten. */\n"
                        + ".cm-md-codeBlock { font-family: Menlo !important; }\n"),
            ])
    }

    @Test func markEditPreferencesAreJSONData() throws {
        let config = try #require(AppConfigs.app(named: "markedit"))
        var reader = try TableReader(
            """
            [appearance]
            mode = "dark"
            light_theme = "github-light"
            dark_theme = "dracula"

            [font]
            name = "Menlo"
            size_pt = 15

            [editor]
            wrap_lines = "at_words"
            """, file: "apps/markedit.toml")
        let preferences = config.read(&reader, home: "/Users/test").preferences
        #expect(reader.problems.isEmpty)
        #expect(preferences.allSatisfy { $0.domain == "app.cyan.markedit" })
        #expect(
            preferences.map(\.key) == [
                "general.appearance", "editor.light-theme", "editor.dark-theme", "editor.font-style",
                "editor.font-size", "editor.line-wrapping",
            ])
        #expect(
            try preferences.map { try json(in: $0.value ?? "") } == [
                "\"dark\"", "\"github-light\"", "\"dracula\"", "{\"customFont\": {\"name\": \"Menlo\"}}", "15.0",
                "true",
            ])
    }

    @Test func markEditListsExtensionsByRegistryID() throws {
        let config = try #require(AppConfigs.app(named: "markedit"))
        var reader = try TableReader(
            "[extensions]\nids = [\"markedit-preview\", \"markedit-theme-one-dark\"]\n", file: "apps/markedit.toml")
        #expect(
            config.read(&reader, home: "/Users/test").extensions == ["markedit-preview", "markedit-theme-one-dark"])
        var wrong = try TableReader("[extensions]\nids = [\"a.b\"]\n", file: "apps/markedit.toml")
        _ = config.read(&wrong, home: "/Users/test")
        #expect(
            wrong.problems.map { Message($0.level, $0.text) } == [
                Message(
                    .error, "extensions.ids should be a list of MarkEdit extension ids, such as \"markedit-preview\"")
            ])
    }

    @Test func markEditLivesInItsContainer() throws {
        let config = try #require(AppConfigs.app(named: "markedit"))
        #expect(config.container == "Library/Containers/app.cyan.markedit")
    }

    /// The JSON held in `document`, a property list document of one data value.
    private func json(in document: String) throws -> String {
        let value = try PropertyListSerialization.propertyList(from: Data(document.utf8), format: nil)
        let data = try #require(value as? Data)
        return try #require(String(bytes: data, encoding: .utf8))
    }
}
