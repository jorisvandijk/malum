import Testing

@testable import MalumCore

/// micro's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    @Test func microWritesItsSettingsBindingsAndColours() throws {
        let (files, problems) = try read(
            """
            [colors]
            text = { fg = "#f8f8f2", bg = "#282a36" }
            type = { fg = "#8be9fd", bg = "#282a36", style = "italic" }
            type_extended = { bg = "#282a36" }

            [editor]
            wrap_lines = "at_words"

            [shortcuts]
            toggle_comment = ["option+slash", "ctrl+slash"]

            [files]
            create_folders = true
            """, app: "micro")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/micro/settings.json",
                    "{\n    \"colorscheme\": \"malum\",\n    \"mkparents\": true,\n    \"softwrap\": true,\n"
                        + "    \"wordwrap\": true\n}\n"),
                AppFile(
                    ".config/micro/bindings.json",
                    "{\n    \"Alt-/\": \"lua:comment.comment\",\n    \"CtrlUnderscore\": \"lua:comment.comment\"\n}\n"),
                AppFile(
                    ".config/micro/colorschemes/malum.micro",
                    Self.header(of: "micro") + "color-link default \"#f8f8f2,#282a36\"\n"
                        + "color-link type \"italic #8be9fd,#282a36\"\ncolor-link type.extended \"default,#282a36\"\n"),
            ])
    }

    @Test func microWrapsLinesAnywhereOrNever() throws {
        let (anywhere, _) = try read("[editor]\nwrap_lines = \"anywhere\"\n", app: "micro")
        #expect(
            anywhere.first?.text
                == "{\n    \"colorscheme\": \"malum\",\n    \"softwrap\": true,\n    \"wordwrap\": false\n}\n")
        let (never, _) = try read("[editor]\nwrap_lines = \"never\"\n", app: "micro")
        #expect(
            never.first?.text
                == "{\n    \"colorscheme\": \"malum\",\n    \"softwrap\": false,\n    \"wordwrap\": false\n}\n")
    }

    @Test func microWithoutSettingsStillUsesItsColours() throws {
        let (files, _) = try read("", app: "micro")
        #expect(files == [AppFile(".config/micro/settings.json", "{\n    \"colorscheme\": \"malum\"\n}\n")])
    }

    @Test func microsWrongValuesAndOldTablesAreProblems() throws {
        let (files, problems) = try read(
            """
            [colors]
            comment = "#6272a4,#282a36"
            shade = { fg = "#ffffff" }

            [shortcuts]
            toggle_comment = "cmd+slash"

            [settings]
            softwrap = true
            """, app: "micro")
        #expect(files == [AppFile(".config/micro/settings.json", "{\n    \"colorscheme\": \"malum\"\n}\n")])
        #expect(
            problems == [
                Message(.warn, "unknown table settings"),
                Message(.warn, "unknown table colors.shade"),
                Message(
                    .error,
                    MessageText(
                        "colors.comment should be a table with a colour fg (or none, for the default), an optional "
                            + "colour bg and an optional style \"bold\", \"italic\" or \"underline\", such as "
                            + "{ fg = \"#f8f8f2\", bg = \"#282a36\" }")),
                Message(
                    .error,
                    MessageText(
                        "shortcuts.toggle_comment should be a shortcut: modifiers cmd, ctrl, option, shift, fn or "
                            + "hyper, then a key, joined by +, such as \"ctrl+option+k\", or a list of them")),
            ])
    }
}
