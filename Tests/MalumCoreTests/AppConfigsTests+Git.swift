import Testing

@testable import MalumCore

/// git's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    @Test func gitWritesItsSettingsAsSections() throws {
        let (files, problems) = try read(
            """
            [user]
            name = "Joris"
            email = "joris@example.com"

            [branches]
            default = "main"

            [hooks]
            folder = "$HOME/.git-hooks"

            [push]
            auto_set_upstream = true

            [github]
            use_ssh = true
            """, app: "git")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(
                    ".config/git/config",
                    Self.header(of: "git") + "[core]\n\thooksPath = \"/Users/test/.git-hooks\"\n\n"
                        + "[init]\n\tdefaultBranch = \"main\"\n\n[push]\n\tautoSetupRemote = true\n\n"
                        + "[url \"git@github.com:\"]\n\tinsteadOf = \"https://github.com/\"\n\n"
                        + "[user]\n\temail = \"joris@example.com\"\n\tname = \"Joris\"\n")
            ])
    }

    @Test func gitWithoutSSHForGitHubWritesNoRule() throws {
        let (files, _) = try read("[github]\nuse_ssh = false\n", app: "git")
        #expect(files == [AppFile(".config/git/config", Self.header(of: "git"))])
    }

    @Test func quotesAndBackslashesAreEscaped() throws {
        let (files, _) = try read("[user]\nname = 'Jo \"J\\D\"'\n", app: "git")
        #expect(files.first?.text == Self.header(of: "git") + "[user]\n\tname = \"Jo \\\"J\\\\D\\\"\"\n")
    }

    @Test func gitsOldTablesAndWrongValuesAreProblems() throws {
        let (_, problems) = try read(
            """
            [settings.user]
            name = "Joris"

            [hooks]
            folder = "~/.git-hooks"

            [push]
            autoSetupRemote = true
            """, app: "git")
        #expect(
            problems == [
                Message(.warn, "unknown table settings"),
                Message(
                    .error, "hooks.folder should be a path, starting with $HOME/ in your home folder or / outside it"),
                Message(.warn, "unknown setting push.autoSetupRemote"),
            ])
    }
}
