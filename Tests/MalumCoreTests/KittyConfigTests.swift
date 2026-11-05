import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct KittyConfigTests {
    private let header =
        "# Written by Malum from apps/kitty.toml in dots. Changes made here are overwritten.\n"

    private func read(_ text: String) throws -> (files: [AppFile], problems: [AppProblem]) {
        KittyConfig().read(ConfigValue.table(try TOMLReader.table(from: text)))
    }

    @Test func everyTableBecomesABlockInOrder() throws {
        let (files, problems) = try read(
            """
            [font]
            name = "Fira Code"
            size = 13.5

            [theme]
            foreground = "#f8f8f2"
            background = "#282a36"

            [settings]
            scrollback_lines = 100000
            enable_audio_bell = false
            enabled_layouts = "splits"

            [keybindings]
            "cmd+b" = "launch --location=vsplit"
            """)
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/kitty/kitty.conf",
                    header + "font_family Fira Code\nfont_size 13.5\n\ninclude theme.conf\n\n"
                        + "enable_audio_bell no\nenabled_layouts splits\nscrollback_lines 100000\n\n"
                        + "map cmd+b launch --location=vsplit\n"),
                AppFile(".config/kitty/theme.conf", header + "background #282a36\nforeground #f8f8f2\n"),
            ])
    }

    @Test func emptyFileWritesOnlyTheHeader() throws {
        let (files, problems) = try read("")
        #expect(problems.isEmpty)
        #expect(files == [AppFile(".config/kitty/kitty.conf", header)])
    }

    @Test func wrongValuesAreErrors() throws {
        let (_, problems) = try read(
            """
            theme = 1

            [font]
            name = 1
            size = "big"

            [settings]
            "two words" = 1
            colors = [1]

            [keybindings]
            "cmd+b" = "a\\nb"
            """)
        #expect(
            problems == [
                AppProblem(.error, at: ["font", "name"], "font.name should be text in quotes"),
                AppProblem(.error, at: ["font", "size"], "font.size should be a number"),
                AppProblem(.error, at: ["theme"], "theme should be a table"),
                AppProblem(
                    .error, at: ["settings", "colors"],
                    "settings.colors should be text on one line, a number, true or false"),
                AppProblem(
                    .error, at: ["settings", "two words"],
                    "settings.\"two words\": the name can't be empty or hold spaces"),
                AppProblem(
                    .error, at: ["keybindings", "cmd+b"],
                    "keybindings.\"cmd+b\" should be text in quotes, on one line"),
            ])
    }

    @Test func unknownKeysAreWarnings() throws {
        let (files, problems) = try read("colour = true\n\n[font]\nstyle = \"bold\"\n")
        #expect(files.count == 1)
        #expect(
            problems == [
                AppProblem(.warn, at: ["colour"], "unknown setting colour"),
                AppProblem(.warn, at: ["font", "style"], "unknown setting font.style"),
            ])
    }
}
