import Testing

@testable import MalumCore

/// The file formats apps' files are written in, read straight from tables.
@Suite(.timeLimit(.minutes(1)))
struct FileFormatTests {
    /// The JSON text of the table `settings` in `toml`, and the problems found.
    private func json(_ toml: String) throws -> (text: String?, problems: [Message]) {
        var reader = try TableReader(toml, file: "apps/sample.toml")
        let text = FileFormat.json(table: "settings").text(from: reader.document, at: [], reader: &reader)
        return (text, reader.problems.map { Message($0.level, $0.text) })
    }

    @Test func jsonHoldsNestedTablesAndLists() throws {
        let (text, problems) = try json(
            """
            [settings]
            "editor.customToolbarItems" = [{ title = "View Mode", icon = "eye" }]
            "extension.markeditPreview" = { syncScroll = true, changeMode = { modes = ["edit", "preview"] } }
            scrollmargin = 1.5
            """)
        #expect(problems.isEmpty)
        #expect(
            text
                == "{\n    \"editor.customToolbarItems\": [{\"icon\": \"eye\", \"title\": \"View Mode\"}],\n"
                + "    \"extension.markeditPreview\": {\"changeMode\": {\"modes\": [\"edit\", \"preview\"]}, "
                + "\"syncScroll\": true},\n    \"scrollmargin\": 1.5\n}\n")
    }

    @Test func jsonEscapesControlCharacters() throws {
        let text = try json("[settings]\nfileformat = \"a\\u0001\\tb\"\n").text
        #expect(text == "{\n    \"fileformat\": \"a\\u0001\\tb\"\n}\n")
    }

    @Test func jsonTakesNoDates() throws {
        let (_, problems) = try json("[settings]\nwhen = 2026-11-05\nnested = [{ at = 2026-11-05 }]\n")
        #expect(
            problems == [
                Message(.error, "settings.nested should be text, a number, true or false, or a list or table of them"),
                Message(.error, "settings.when should be text, a number, true or false, or a list or table of them"),
            ])
    }

    @Test func aFileForEachTableNeedsPlainNames() throws {
        let file = AppConfigFile(
            ".config/sample/*.conf", .lines([LineBlock(nil, prefix: "color-link", quoted: .double)]), each: "schemes")
        var reader = try TableReader(
            """
            [schemes]
            plain = 1

            [schemes.".hidden"]
            default = "#fff"

            [schemes.dark]
            default = "#000000"
            """, file: "apps/sample.toml")
        let files = file.read(reader.document, app: "sample", reader: &reader)
        #expect(
            files == [
                AppFile(
                    ".config/sample/dark.conf",
                    AppConfigsTests.header(of: "sample") + "color-link default \"#000000\"\n")
            ])
        #expect(
            reader.problems.map { Message($0.level, $0.text) } == [
                Message(.error, "schemes.\".hidden\": the name can't be empty, start with a dot or hold /"),
                Message(.error, "schemes.plain should be a table"),
            ])
    }
}
