import Foundation
import Testing

@testable import MalumCore

/// MarkEdit's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    /// Where MarkEdit reads its settings file and CSS, relative to home.
    private static let markEditDocuments = "Library/Containers/app.cyan.markedit/Data/Documents"

    @Test func markEditWritesSettingsWithNestedTablesAndCSS() throws {
        let (files, problems) = try read(
            """
            [settings]
            "editor.autoSaveWhenIdle" = true
            "editor.customToolbarItems" = [{ title = "View Mode", icon = "eye" }]
            "extension.markeditPreview" = { syncScroll = true, changeMode = { modes = ["edit", "preview"] } }

            [css]
            text = ".cm-md-codeBlock { font-family: Menlo !important; }"
            """, app: "markedit")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    "\(Self.markEditDocuments)/settings.json",
                    "{\n    \"editor.autoSaveWhenIdle\": true,\n"
                        + "    \"editor.customToolbarItems\": [{\"icon\": \"eye\", \"title\": \"View Mode\"}],\n"
                        + "    \"extension.markeditPreview\": {\"changeMode\": {\"modes\": [\"edit\", \"preview\"]}, "
                        + "\"syncScroll\": true}\n}\n"),
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
            [preferences]
            "editor.dark-theme" = "dracula"
            "editor.font-size" = 15.0
            "editor.font-style" = { customFont = { name = "Menlo" } }
            """, file: "apps/markedit.toml")
        let preferences = config.read(&reader).preferences
        #expect(reader.problems.isEmpty)
        #expect(preferences.allSatisfy { $0.domain == "app.cyan.markedit" })
        #expect(
            try preferences.map { try json(in: $0.value ?? "") } == [
                "\"dracula\"", "15.0", "{\"customFont\": {\"name\": \"Menlo\"}}",
            ])
    }

    @Test func markEditListsExtensionsByRegistryID() throws {
        let config = try #require(AppConfigs.app(named: "markedit"))
        var reader = try TableReader(
            "[extensions]\nids = [\"markedit-preview\", \"markedit-theme-one-dark\"]\n", file: "apps/markedit.toml")
        #expect(config.read(&reader).extensions == ["markedit-preview", "markedit-theme-one-dark"])
        var wrong = try TableReader("[extensions]\nids = [\"a.b\"]\n", file: "apps/markedit.toml")
        _ = config.read(&wrong)
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
