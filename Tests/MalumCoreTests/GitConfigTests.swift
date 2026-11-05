import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct GitConfigTests {
    private let header =
        "# Written by Malum from apps/git.toml in dots. Changes made here are overwritten.\n"

    private func read(_ text: String) throws -> (files: [AppFile], problems: [AppProblem]) {
        GitConfig().read(ConfigValue.table(try TOMLReader.table(from: text)))
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
                AppProblem(.error, at: ["settings"], "settings should be a table"),
                AppProblem(.error, at: ["ignore", "patterns"], "ignore.patterns should be a list of text in quotes"),
                AppProblem(.error, at: ["attributes", "lines"], "attributes.lines should be a list of text in quotes"),
            ])
    }

    @Test func wrongSettingValuesAreErrors() throws {
        let (_, problems) = try read("[settings]\nuser = 1\n\n[settings.core]\nratio = 1.5\n")
        #expect(
            problems == [
                AppProblem(
                    .error, at: ["settings", "core", "ratio"],
                    "settings.core.ratio should be text, a whole number, true or false, or a list of them"),
                AppProblem(.error, at: ["settings", "user"], "settings.user should be a table"),
            ])
    }

    @Test func unknownKeysAreWarnings() throws {
        let (files, problems) = try read("colour = true\n\n[ignore]\nfiles = []\n")
        #expect(files.count == 1)
        #expect(
            problems == [
                AppProblem(.warn, at: ["colour"], "unknown setting colour"),
                AppProblem(.warn, at: ["ignore", "files"], "unknown setting ignore.files"),
            ])
    }
}
