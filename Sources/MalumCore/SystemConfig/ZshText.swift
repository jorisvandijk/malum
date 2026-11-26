/// zsh's login and interactive startup files, written from the tables of `apps/zsh.toml` in Silo's
/// layout: `.zprofile` from `[homebrew]` and `[path]`, and `.zshrc` from the plugins, history,
/// options, sourced files, functions, prompt and aliases. The plugins load from Homebrew.
enum ZshText {
    /// zsh's startup files written from more than one table.
    enum File: Sendable {
        /// `.zprofile`, for login shells.
        case profile
        /// `.zshrc`, for interactive shells.
        case rc
    }

    /// A switch in a table and the lines it writes when it's on, and when it's off.
    private struct Switch {
        /// The switch's key.
        let key: String
        /// The lines written when it's on.
        let on: String
        /// The lines written when it's off, or nil for none.
        var off: String?
        /// Whether it's on when it's left out.
        var isOn = false
    }

    /// The tables `file` is written from.
    static func tables(of file: File) -> [String] {
        switch file {
        case .profile:
            [homebrewTable, pathTable]
        case .rc:
            rcTables
        }
    }

    /// The text of `file` from `table`, found at `path`, or nil when it would be empty.
    static func text(of file: File, from table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        switch file {
        case .profile:
            profile(table, at: path, reader: &reader)
        case .rc:
            rc(table, at: path, reader: &reader)
        }
    }

    /// The tables `.zshrc` reads.
    private static let rcTables = [
        pluginsTable, historyTable, optionsTable, sourceTable, functionsTable, promptTable, aliases,
    ]

    private static let homebrewTable = "homebrew"
    private static let pathTable = "path"
    private static let pluginsTable = "plugins"
    private static let historyTable = "history"
    private static let optionsTable = "options"
    private static let sourceTable = "source"
    private static let functionsTable = "functions"
    private static let promptTable = "prompt"
    private static let aliases = "aliases"
    /// The tables of zsh-abbr's file, which `.zshrc` loads zsh-abbr for when they hold any.
    private static let abbreviationTables = ["abbreviations", "global_abbreviations"]
    /// The key of `[path]` that lists the folders put in front of `PATH`.
    private static let prependKey = "prepend"
    /// The key of `[source]` that lists the files to load.
    private static let filesKey = "files"
    /// The key of `[plugins]` that lists zoxide's options.
    private static let zoxideOptionsKey = "zoxide_options"
    /// The keys of `[prompt]`, by the variable each sets.
    private static let prompts = [("text", "PROMPT"), ("right", "RPROMPT")]
    /// The keys of `[history]` that aren't switches, by the variable each sets, and their defaults.
    private static let historyValues = [("size", "HISTSIZE", "10000"), ("save", "SAVEHIST", "10000")]
    /// The key of `[history]` that names the history file.
    private static let historyFileKey = "file"
    /// Where Homebrew keeps zsh-abbr.
    private static let abbrFolder = "\(Brew.shareFolder)/zsh-abbr"

    private static let shellenv = Switch(key: "shellenv", on: "eval \"$(\(Brew.path) shellenv)\"\n")
    private static let completion = Switch(key: "completion", on: "autoload -U compinit && compinit -u\n", isOn: true)
    private static let autosuggestions = Switch(
        key: "autosuggestions", on: "source \(Brew.shareFolder)/zsh-autosuggestions/zsh-autosuggestions.zsh\n")
    private static let kitty = Switch(
        key: "kitty_integration",
        on: """
            if test -n "$KITTY_INSTALLATION_DIR"; then
              export KITTY_SHELL_INTEGRATION="no-rc"
              autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
              kitty-integration
              unfunction kitty-integration
            fi

            """)
    private static let fzf = Switch(key: "fzf", on: "if [[ $options[zle] = on ]]; then\n  source <(fzf --zsh)\nfi\n")
    /// The key of `[plugins]` that loads zoxide.
    private static let zoxideKey = "zoxide"
    private static let highlighting = Switch(
        key: "syntax_highlighting",
        on: "source \(Brew.shareFolder)/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n")
    /// The history switches, each with the zsh option it sets and whether it's on when left out.
    private static let historySwitches = [
        ("ignore_dups", "HIST_IGNORE_DUPS", true), ("ignore_all_dups", "HIST_IGNORE_ALL_DUPS", false),
        ("save_no_dups", "HIST_SAVE_NO_DUPS", false), ("find_no_dups", "HIST_FIND_NO_DUPS", false),
        ("ignore_space", "HIST_IGNORE_SPACE", true), ("expire_dups_first", "HIST_EXPIRE_DUPS_FIRST", false),
        ("share", "SHARE_HISTORY", true), ("extended", "EXTENDED_HISTORY", false),
    ].map { key, option, isOn in
        Switch(key: key, on: "setopt \(option)\n", off: "unsetopt \(option)\n", isOn: isOn)
    }

    /// `.zprofile` from `table`, found at `path`, or nil when it would be empty.
    private static func profile(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        var lines = ""
        let homebrew = reader.table(table, homebrewTable, at: path)
        reader.unknownKeys(homebrew, at: path + [homebrewTable], known: [shellenv.key])
        lines += switches([shellenv], in: homebrew, at: path + [homebrewTable], reader: &reader)
        let paths = reader.table(table, pathTable, at: path)
        reader.unknownKeys(paths, at: path + [pathTable], known: [prependKey])
        let folders = reader.texts(paths, prependKey, at: path + [pathTable]) ?? []
        if !folders.isEmpty {
            lines += "export PATH=\(Escaping.quoted((folders + ["$PATH"]).joined(separator: ":"), controls: .none))\n"
        }
        return lines.isEmpty ? nil : lines
    }

    /// `.zshrc` from `table`, found at `path`. It's never empty.
    private static func rc(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String {
        let plugins = reader.table(table, pluginsTable, at: path)
        let pluginsPath = path + [pluginsTable]
        let usesAbbr = abbreviationTables.contains { table[$0].map { $0 != .table([:]) } ?? false }
        var blocks = ["typeset -U path cdpath fpath manpath\n" + (usesAbbr ? "fpath+=(\(abbrFolder))\n" : "")]
        blocks.append(switches([completion, autosuggestions], in: plugins, at: pluginsPath, reader: &reader))
        blocks.append(history(reader.table(table, historyTable, at: path), at: path + [historyTable], reader: &reader))
        blocks.append(switches([kitty], in: plugins, at: pluginsPath, reader: &reader))
        blocks.append(options(reader.table(table, optionsTable, at: path), at: path + [optionsTable], reader: &reader))
        blocks.append(sources(reader.table(table, sourceTable, at: path), at: path + [sourceTable], reader: &reader))
        blocks += functions(reader.table(table, functionsTable, at: path), at: path + [functionsTable], reader: &reader)
        blocks.append(prompt(reader.table(table, promptTable, at: path), at: path + [promptTable], reader: &reader))
        blocks.append(switches([fzf], in: plugins, at: pluginsPath, reader: &reader))
        blocks.append(zoxideLine(plugins, at: pluginsPath, reader: &reader))
        let aliasBlock = LineBlock(aliases, prefix: "alias", separator: "=", quoted: .shell)
        let aliasTable = reader.table(table, aliases, at: path)
        blocks.append(LineText.text(aliasTable, at: path + [aliases], block: aliasBlock, reader: &reader) ?? "")
        blocks.append(usesAbbr ? "source \(abbrFolder)/zsh-abbr.zsh\n" : "")
        blocks.append(switches([highlighting], in: plugins, at: pluginsPath, reader: &reader))
        let known = [completion, autosuggestions, kitty, fzf, highlighting].map(\.key) + [zoxideKey, zoxideOptionsKey]
        reader.unknownKeys(plugins, at: pluginsPath, known: known)
        return blocks.filter { !$0.isEmpty }.joined(separator: "\n")
    }

    /// The lines of each of `list` in `table`, found at `path`, that's on, or off and writes lines then.
    private static func switches(
        _ list: [Switch], in table: ConfigTable, at path: [String], reader: inout TableReader
    ) -> String {
        list.compactMap { item in
            let isOn = reader.flag(table, item.key, at: path) ?? item.isOn
            return isOn ? item.on : item.off
        }.joined()
    }

    /// The history variables and options from `table`, found at `path`.
    private static func history(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String {
        let known = historyValues.map(\.0) + [historyFileKey] + historySwitches.map(\.key)
        reader.unknownKeys(table, at: path, known: known)
        var lines = historyValues.map { key, variable, fallback in
            guard let value = table[key] else { return "\(variable)=\"\(fallback)\"\n" }
            guard case .integer(let number) = value, number >= 0 else {
                reader.expect(path + [key], SettingKind.integer)
                return "\(variable)=\"\(fallback)\"\n"
            }
            return "\(variable)=\"\(number)\"\n"
        }.joined()
        let file = reader.text(table, historyFileKey, at: path)
        lines += "HISTFILE=\(Escaping.quoted(file ?? "$HOME/.zsh_history", controls: .none))\n"
        if file != nil { lines += "mkdir -p \"$(dirname \"$HISTFILE\")\"\n" }
        return lines + "setopt HIST_FCNTL_LOCK\n" + switches(historySwitches, in: table, at: path, reader: &reader)
    }

    /// A `setopt` or `unsetopt` line for each option in `table`, found at `path`.
    private static func options(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String {
        table.keys.sorted().compactMap { name in
            guard isName(name, at: path, reader: &reader) else { return nil }
            return (reader.flag(table, name, at: path) ?? false)
                ? "setopt \(name)\n" : "unsetopt \(name)\n"
        }.joined()
    }

    /// A `source` line for each of the files in `table`, found at `path`.
    private static func sources(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String {
        reader.unknownKeys(table, at: path, known: [filesKey])
        return (reader.texts(table, filesKey, at: path) ?? []).map {
            "source \(Escaping.quoted($0, controls: .none))\n"
        }.joined()
    }

    /// Each function in `table`, found at `path`, with its body indented.
    private static func functions(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> [String] {
        table.keys.sorted().compactMap { name in
            guard isName(name, at: path, reader: &reader) else { return nil }
            guard let body = reader.text(table, name, at: path) else { return nil }
            let lines = body.split(separator: "\n", omittingEmptySubsequences: false)
            let indented = (body.hasSuffix("\n") ? lines.dropLast() : lines[...]).map {
                $0.isEmpty ? "\n" : "  \($0)\n"
            }
            return "\(name)() {\n\(indented.joined())}\n"
        }
    }

    /// The prompt variables from `table`, found at `path`.
    private static func prompt(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String {
        reader.unknownKeys(table, at: path, known: prompts.map(\.0))
        return prompts.compactMap { key, variable in
            reader.text(table, key, at: path).map { "\(variable)=\(Escaping.shell($0))\n" }
        }.joined()
    }

    /// The line that loads zoxide with its options from `plugins`, found at `path`, when it's on.
    private static func zoxideLine(_ plugins: ConfigTable, at path: [String], reader: inout TableReader) -> String {
        let options = (reader.texts(plugins, zoxideOptionsKey, at: path) ?? []).map { " " + Escaping.shell($0) }
        guard reader.flag(plugins, zoxideKey, at: path) ?? false else { return "" }
        return "eval \"$(zoxide init zsh\(options.joined()))\"\n"
    }

    /// Whether `name`, a key of the table at `path`, can be a zsh name, with an error when not.
    private static func isName(_ name: String, at path: [String], reader: inout TableReader) -> Bool {
        guard !name.isEmpty, !name.contains(where: \.isWhitespace) else {
            reader.add(.error, at: path + [name], .notLineName(TableReader.dotted(path + [name])))
            return false
        }
        return true
    }
}
