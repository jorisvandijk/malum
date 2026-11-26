import Testing

@testable import MalumCore

/// zsh's app config, with the helpers of `AppConfigsTests`.
extension AppConfigsTests {
    /// A `zsh.toml` with every table.
    private static let zshFile = #"""
        [homebrew]
        shellenv = true

        [path]
        prepend = ["$HOME/.local/bin", "$HOME/go/bin"]

        [plugins]
        autosuggestions = true
        syntax_highlighting = true
        fzf = true
        zoxide = true
        zoxide_options = ["--cmd", "cd"]
        kitty_integration = true

        [options]
        hist_verify = true
        beep = false

        [source]
        files = ["$HOME/git/scripts/j.zsh"]

        [prompt]
        text = '%~ %# '

        [functions]
        gc = 'git commit -m "$*"'
        h = '''
        local cmd

        print -z "$cmd"
        '''

        [history]
        size = 200000
        save_no_dups = true
        share = false

        [environment]
        EDITOR = "micro"

        [aliases]
        ".." = "cd .."
        say = "echo it's $PWD"

        [abbreviations]
        gs = "git status"

        [global_abbreviations]
        pc = "| pbcopy"
        """#

    /// What `zshFile` writes to `.zshrc`.
    private static let zshrc = """
        typeset -U path cdpath fpath manpath
        fpath+=(/opt/homebrew/share/zsh-abbr)

        autoload -U compinit && compinit -u
        source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

        HISTSIZE="200000"
        SAVEHIST="10000"
        HISTFILE="$HOME/.zsh_history"
        setopt HIST_FCNTL_LOCK
        setopt HIST_IGNORE_DUPS
        unsetopt HIST_IGNORE_ALL_DUPS
        setopt HIST_SAVE_NO_DUPS
        unsetopt HIST_FIND_NO_DUPS
        setopt HIST_IGNORE_SPACE
        unsetopt HIST_EXPIRE_DUPS_FIRST
        unsetopt SHARE_HISTORY
        unsetopt EXTENDED_HISTORY

        if test -n "$KITTY_INSTALLATION_DIR"; then
          export KITTY_SHELL_INTEGRATION="no-rc"
          autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
          kitty-integration
          unfunction kitty-integration
        fi

        unsetopt beep
        setopt hist_verify

        source "$HOME/git/scripts/j.zsh"

        gc() {
          git commit -m "$*"
        }

        h() {
          local cmd

          print -z "$cmd"
        }

        PROMPT='%~ %# '

        if [[ $options[zle] = on ]]; then
          source <(fzf --zsh)
        fi

        eval "$(zoxide init zsh --cmd cd)"

        alias ..='cd ..'
        alias say='echo it'\\''s $PWD'

        source /opt/homebrew/share/zsh-abbr/zsh-abbr.zsh

        source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        """

    @Test func zshWritesItsFiles() throws {
        let (files, problems) = try read(
            Self.zshFile, app: "zsh")
        let header = Self.header(of: "zsh")
        #expect(problems.isEmpty)
        #expect(
            files == [
                AppFile(".zshenv", header + "export EDITOR=\"micro\"\n"),
                AppFile(
                    ".zprofile",
                    header + "eval \"$(/opt/homebrew/bin/brew shellenv)\"\n"
                        + "export PATH=\"$HOME/.local/bin:$HOME/go/bin:$PATH\"\n"),
                AppFile(".zshrc", header + Self.zshrc),
                AppFile(
                    ".config/zsh-abbr/user-abbreviations",
                    header + "abbr gs='git status'\n\nabbr -g pc='| pbcopy'\n"),
            ])
    }

    @Test func zshWithNothingWritesOnlyZshrcWithItsDefaults() throws {
        let (files, problems) = try read("", app: "zsh")
        #expect(problems.isEmpty)
        #expect(files.map(\.path) == [".zshrc"])
        #expect(files.first?.text.contains("compinit") == true)
        #expect(files.first?.text.contains("setopt SHARE_HISTORY\n") == true)
    }

    @Test func wrongZshSettingsAreErrors() throws {
        let (files, problems) = try read(
            """
            [plugins]
            fzf = "yes"
            colour = true

            [history]
            size = -1

            [options]
            "no space" = true

            [zshrc]
            text = "setopt beep"
            """, app: "zsh")
        #expect(files.map(\.path) == [".zshrc"])
        #expect(
            problems == [
                Message(.warn, "unknown table zshrc"),
                Message(.error, "history.size should be a whole number"),
                Message(.error, "options.\"no space\": the name can't be empty or hold spaces"),
                Message(.error, "plugins.fzf should be true or false"),
                Message(.warn, "unknown setting plugins.colour"),
            ])
    }

    @Test func unknownHomebrewSettingIsOnlyAWarning() throws {
        let (files, problems) = try read("[homebrew]\nshellenv = true\nanalytics = false\n", app: "zsh")
        #expect(files.map(\.path) == [".zprofile", ".zshrc"])
        #expect(problems == [Message(.warn, "unknown setting homebrew.analytics")])
    }
}
