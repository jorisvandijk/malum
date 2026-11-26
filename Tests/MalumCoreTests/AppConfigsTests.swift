import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct AppConfigsTests {
    private let header = Self.header(of: "git")

    /// The line at the top of each file of `app` that has comments.
    static func header(of app: String) -> String {
        "# Written by Malum from apps/\(app).toml in dots. Changes made here are overwritten.\n"
    }

    /// What `app` makes of its TOML `text`.
    func read(
        _ text: String, app: String = "git"
    ) throws -> (files: [AppFile], problems: [Message]) {
        let config = try #require(AppConfigs.app(named: app))
        var reader = try TableReader(text, file: "apps/\(app).toml")
        let files = config.read(&reader, home: "/Users/test").files
        return (files, reader.problems.map { Message($0.level, $0.text) })
    }

    @Test func settingsBecomeSectionsInOrder() throws {
        let (files, problems) = try read(
            """
            [settings.user]
            name = "Joris"
            email = "joris@example.com"

            [settings.push]
            autoSetupRemote = true

            [settings.core]
            abbrev = 12
            """)
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/git/config",
                    header + "[core]\n\tabbrev = 12\n\n[push]\n\tautoSetupRemote = true\n\n"
                        + "[user]\n\temail = \"joris@example.com\"\n\tname = \"Joris\"\n")
            ])
    }

    @Test func dottedSectionIsASubsectionAndListsRepeatTheirKey() throws {
        let (files, _) = try read(
            """
            [settings."url.git@github.com:"]
            insteadOf = ["https://github.com/", "gh:"]
            """)
        #expect(
            files.first?.text
                == header + "[url \"git@github.com:\"]\n\tinsteadOf = \"https://github.com/\"\n\tinsteadOf = \"gh:\"\n")
    }

    @Test func quotesAndBackslashesAreEscaped() throws {
        let (files, _) = try read("[settings.alias]\nsay = 'echo \"hi\\there\"'\n")
        #expect(files.first?.text == header + "[alias]\n\tsay = \"echo \\\"hi\\\\there\\\"\"\n")
    }

    @Test func ignoreAndAttributesGetTheirOwnFiles() throws {
        let (files, problems) = try read(
            """
            [ignore]
            patterns = [".DS_Store", "*.swp"]

            [attributes]
            lines = ["*.pdf diff=pdf"]
            """)
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(".config/git/config", header),
                AppFile(".config/git/ignore", header + ".DS_Store\n*.swp\n"),
                AppFile(".config/git/attributes", header + "*.pdf diff=pdf\n"),
            ])
    }

    @Test func emptyListsWriteNoFile() throws {
        let (files, _) = try read("[ignore]\npatterns = []\n")
        #expect(files.map(\.path) == [".config/git/config"])
    }

    @Test func wrongValuesAreErrors() throws {
        let (_, problems) = try read(
            """
            settings = 1

            [ignore]
            patterns = [1]

            [attributes]
            lines = "*.pdf"
            """)
        #expect(
            problems == [
                Message(.error, "settings should be a table"),
                Message(.error, "ignore.patterns should be a list of text in quotes"),
                Message(.error, "attributes.lines should be a list of text in quotes"),
            ])
    }

    @Test func wrongSettingValuesAreErrors() throws {
        let (_, problems) = try read("[settings]\nuser = 1\n\n[settings.core]\nratio = 1.5\n")
        #expect(
            problems == [
                Message(.error, "settings.core.ratio should be text, a whole number, true or false, or a list of them"),
                Message(.error, "settings.user should be a table"),
            ])
    }

    @Test func unknownKeysAreWarnings() throws {
        let (files, problems) = try read("colour = true\n\n[ignore]\nfiles = []\n")
        #expect(files.count == 1)
        #expect(
            problems == [
                Message(.warn, "unknown setting colour"),
                Message(.warn, "unknown setting ignore.files"),
            ])
    }

    // MARK: - kitty

    @Test func kittyWritesThemeSettingsAndShortcutsInBlocks() throws {
        let (files, problems) = try read(
            """
            [theme]
            foreground = "#f8f8f2"

            [settings]
            font_family = "Fira Code"
            font_size = 13.5
            scrollback_lines = 100000
            enable_audio_bell = false

            [keybindings]
            "cmd+b" = "launch --location=vsplit"
            """, app: "kitty")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/kitty/kitty.conf",
                    Self.header(of: "kitty") + "foreground #f8f8f2\n\n"
                        + "enable_audio_bell no\nfont_family Fira Code\nfont_size 13.5\nscrollback_lines 100000\n\n"
                        + "map cmd+b launch --location=vsplit\n")
            ])
    }

    @Test func kittyWithoutSettingsWritesOnlyTheHeader() throws {
        let (files, _) = try read("", app: "kitty")
        #expect(files == [AppFile(".config/kitty/kitty.conf", Self.header(of: "kitty"))])
    }

    @Test func wrongLineValuesAreErrors() throws {
        let expected = "should be text on one line, a number, true or false, or a list of them"
        let (_, problems) = try read(
            """
            theme = 1

            [settings]
            "two words" = 1
            colors = [[1]]

            [keybindings]
            "cmd+b" = "a\\nb"
            """, app: "kitty")
        #expect(
            problems == [
                Message(.error, "theme should be a table"),
                Message(.error, "settings.colors \(expected)"),
                Message(.error, "settings.\"two words\": the name can't be empty or hold spaces"),
                Message(.error, "keybindings.\"cmd+b\" \(expected)"),
            ])
    }

    @Test func kittyListsRepeatTheirOption() throws {
        let (files, problems) = try read(
            "[settings]\nsymbol_map = [\"U+E0A0 Nerd\", \"U+F000 Awesome\"]\n", app: "kitty")
        #expect(problems.isEmpty)
        #expect(
            files.first?.text
                == Self.header(of: "kitty") + "symbol_map U+E0A0 Nerd\nsymbol_map U+F000 Awesome\n")
    }
}
