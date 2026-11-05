import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct MicroConfigTests {
    private func read(_ text: String) throws -> (files: [AppFile], problems: [AppProblem]) {
        MicroConfig().read(ConfigValue.table(try TOMLReader.table(from: text)))
    }

    @Test func settingsAndBindingsBecomeJSON() throws {
        let (files, problems) = try read(
            """
            [settings]
            colorscheme = "dracula"
            tabsize = 4
            softwrap = true
            scrollmargin = 1.5
            rmtrailingws = false
            ignore = ["*.o", "a\\"b"]

            [bindings]
            "Alt-/" = "lua:comment.comment"
            """)
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/micro/settings.json",
                    "{\n    \"colorscheme\": \"dracula\",\n    \"ignore\": [\"*.o\", \"a\\\"b\"],\n"
                        + "    \"rmtrailingws\": false,\n    \"scrollmargin\": 1.5,\n    \"softwrap\": true,\n"
                        + "    \"tabsize\": 4\n}\n"),
                AppFile(".config/micro/bindings.json", "{\n    \"Alt-/\": \"lua:comment.comment\"\n}\n"),
            ])
    }

    @Test func emptyFileWritesEmptySettings() throws {
        let (files, problems) = try read("")
        #expect(problems.isEmpty)
        #expect(files == [AppFile(".config/micro/settings.json", "{}\n")])
    }

    @Test func colorschemeBecomesColorLinks() throws {
        let (files, problems) = try read(
            """
            [colorschemes.dracula]
            default = "#F8F8F2,#282A36"
            "constant.string" = "italic #F1FA8C"
            """)
        #expect(problems.isEmpty)
        #expect(
            files.last
                == AppFile(
                    ".config/micro/colorschemes/dracula.micro",
                    "# Written by Malum from apps/micro.toml in dots. Changes made here are overwritten.\n"
                        + "color-link constant.string \"italic #F1FA8C\"\ncolor-link default \"#F8F8F2,#282A36\"\n"))
    }

    @Test func wrongValuesAreErrors() throws {
        let (files, problems) = try read(
            """
            [settings]
            when = 2026-11-05
            tabs = [1]

            [bindings]
            "Ctrl-s" = true

            [colorschemes.".hidden"]
            default = "#fff"

            [colorschemes.dark]
            comment = 'say "hi"'
            """)
        #expect(files.map(\.path) == [".config/micro/settings.json", ".config/micro/colorschemes/dark.micro"])
        #expect(
            problems == [
                AppProblem(
                    .error, at: ["settings", "tabs"],
                    "settings.tabs should be text, a number, true or false, or a list of text"),
                AppProblem(
                    .error, at: ["settings", "when"],
                    "settings.when should be text, a number, true or false, or a list of text"),
                AppProblem(
                    .error, at: ["bindings", "Ctrl-s"], "bindings.Ctrl-s should be text in quotes, on one line"),
                AppProblem(
                    .error, at: ["colorschemes", ".hidden"],
                    "colorschemes.\".hidden\": the name can't be empty, start with a dot or hold /"),
                AppProblem(
                    .error, at: ["colorschemes", "dark", "comment"],
                    "colorschemes.dark.comment should be text in quotes, on one line, without \""),
            ])
    }

    @Test func controlCharactersAreEscaped() throws {
        let (files, _) = try read("[settings]\nfileformat = \"a\\u0001\\tb\"\n")
        #expect(files.first?.text == "{\n    \"fileformat\": \"a\\u0001\\tb\"\n}\n")
    }
}
