import Testing

@testable import MalumCore

/// zsh's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    @Test func zshWritesItsFiles() throws {
        let (files, problems) = try read(
            #"""
            [environment]
            EDITOR = "micro"
            NOTES = "$HOME/notes \"mine\""

            [profile]
            text = 'eval "$(/opt/homebrew/bin/brew shellenv)"'

            [aliases]
            ".." = "cd .."
            ll = "ls"
            say = "echo it's $PWD"

            [zshrc]
            text = """
            setopt share_history
            PROMPT='%~ %# '
            """

            [abbreviations]
            gs = "git status"

            [global_abbreviations]
            pc = "| pbcopy"
            """#, app: "zsh")
        let header = Self.header(of: "zsh")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(".zshenv", header + "export EDITOR=\"micro\"\nexport NOTES=\"$HOME/notes \\\"mine\\\"\"\n"),
                AppFile(".zprofile", header + "eval \"$(/opt/homebrew/bin/brew shellenv)\"\n"),
                AppFile(
                    ".zshrc",
                    header + "alias ..='cd ..'\nalias ll=ls\nalias say='echo it'\\''s $PWD'\n\n"
                        + "setopt share_history\nPROMPT='%~ %# '\n"),
                AppFile(
                    ".config/zsh-abbr/user-abbreviations",
                    header + "abbr gs='git status'\n\nabbr -g pc='| pbcopy'\n"),
            ])
    }

    @Test func zshWithNothingWritesOnlyZshrc() throws {
        let (files, problems) = try read("[zshrc]\ntext = \"\"", app: "zsh")
        #expect(problems.isEmpty)
        #expect(files == [AppFile(".zshrc", Self.header(of: "zsh"))])
    }

    @Test func wrongZshTextIsAnError() throws {
        let (files, problems) = try read("[zshrc]\ntext = 1\nlines = []", app: "zsh")
        #expect(files == [AppFile(".zshrc", Self.header(of: "zsh"))])
        #expect(
            problems == [
                Message(.warn, "unknown setting zshrc.lines"),
                Message(.error, "zshrc.text should be text in quotes"),
            ])
    }
}
