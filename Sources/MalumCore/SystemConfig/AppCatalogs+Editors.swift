/// The catalogs of the text editors, whose settings go into their own JSON files, and for MarkEdit
/// into its preferences too.
extension AppCatalogs {
    /// The font sizes the editors take, in points.
    private static let fontSizes = 6.0...100.0

    // MARK: - VSCodium

    /// A key in VSCodium's `settings.json`.
    private static func vscodium(_ key: String) -> CatalogSetting.Target {
        .file(["settings", key])
    }

    /// `apps/vscodium.toml`. The font goes to the editor and the terminal alike, with `monospace`
    /// after it for the editor, so a missing font still shows as one.
    static let vscodium = Catalog(
        file: Paths.appFile(named: "vscodium"),
        tables: [
            CatalogTable(
                name: "appearance", about: "How VSCodium looks.",
                settings: [
                    CatalogSetting(
                        "theme",
                        "The colour theme, by the name VSCodium's theme picker shows, such as \"Dracula Theme\".",
                        .text(.plain), [vscodium("workbench.colorTheme")])
                ]),
            CatalogTable(
                name: "font", about: "The font of the editor and the terminal.",
                settings: [
                    CatalogSetting(
                        "family",
                        "The font's family name, such as \"CaskaydiaCove Nerd Font Mono\". \(Project.name) writes it with "
                            + "monospace after it, so a missing font still shows as one.",
                        .text(.fontList(fallback: "monospace")),
                        [vscodium("editor.fontFamily"), vscodium("terminal.integrated.fontFamily")]),
                    CatalogSetting(
                        "size_pt", "The font's size.", .number(.pt, fontSizes, decimal: false),
                        [vscodium("editor.fontSize"), vscodium("terminal.integrated.fontSize")]),
                    CatalogSetting(
                        "ligatures", "Whether the editor joins letters the font has ligatures for, such as -> and !=.",
                        .flag, [vscodium("editor.fontLigatures")]),
                ]),
            CatalogTable(
                name: "editor", about: "How the editor works.",
                settings: [
                    CatalogSetting(
                        "auto_save",
                        "When the editor saves a changed file by itself: after a short delay, when it loses focus, "
                            + "when the window does, or never.",
                        .choice([
                            .word("off", .string("off")), .word("after_delay", .string("afterDelay")),
                            .word("on_focus_change", .string("onFocusChange")),
                            .word("on_window_change", .string("onWindowChange")),
                        ]), [vscodium("files.autoSave")])
                ]),
            CatalogTable(
                name: "updates", about: "Whether VSCodium and its extensions look for new versions.",
                settings: [
                    CatalogSetting(
                        "auto_check", "Whether VSCodium checks for and downloads new versions of itself.",
                        .flagAs(on: .string("default"), off: .string("none")), [vscodium("update.mode")]),
                    CatalogSetting(
                        "auto_check_extensions", "Whether VSCodium checks for new versions of its extensions.", .flag,
                        [vscodium("extensions.autoCheckUpdates")]),
                ]),
            CatalogTable(
                name: "privacy", about: "What VSCodium sends about how it's used and when it crashes.",
                settings: [
                    CatalogSetting(
                        "telemetry",
                        "What VSCodium and its extensions may report: nothing, crashes, errors, or all usage.",
                        .choice([
                            .word("off", .string("off")), .word("crashes", .string("crash")),
                            .word("errors", .string("error")), .word("all", .string("all")),
                        ]), [vscodium("telemetry.telemetryLevel")]),
                    CatalogSetting(
                        "send_crash_reports", "Whether VSCodium sends a report when it crashes.", .flag,
                        [.file(["argv", "enable-crash-reporter"])]),
                ]),
            CatalogTable(
                name: "assistant", about: "The coding assistant extension in `[extensions]`.",
                settings: [
                    CatalogSetting(
                        "hide_onboarding", "Whether the extension skips the welcome screen it shows at first.",
                        .flag, [vscodium("claudeCode.hideOnboarding")])
                ]),
        ])

    // MARK: - MarkEdit

    /// A MarkEdit preference.
    private static func markEdit(_ key: String) -> CatalogSetting.Target {
        .domain(Domain.markEdit, key)
    }

    /// `apps/markedit.toml`.
    static let markEdit = Catalog(
        file: Paths.appFile(named: "markedit"),
        tables: [
            CatalogTable(
                name: "appearance", about: "How MarkEdit looks. MarkEdit's settings, General and Editor.",
                settings: [
                    CatalogSetting(
                        "mode", "Light, dark, or following macOS.",
                        .choice([
                            .word("system", .string("system")), .word("light", .string("light")),
                            .word("dark", .string("dark")),
                        ]), [markEdit("general.appearance")]),
                    CatalogSetting(
                        "light_theme",
                        "The theme in light mode, by its name in MarkEdit's settings, such as \"github-light\".",
                        .text(.plain), [markEdit("editor.light-theme")]),
                    CatalogSetting(
                        "dark_theme", "The theme in dark mode, such as \"dracula\".", .text(.plain),
                        [markEdit("editor.dark-theme")]),
                ]),
            CatalogTable(
                name: "font", about: "The editor's font.",
                settings: [
                    CatalogSetting(
                        "name",
                        "The font's PostScript name, as Font Book shows it, such as \"CaskaydiaCoveNFM-Regular\".",
                        .text(.nested(["customFont", "name"])), [markEdit("editor.font-style")]),
                    CatalogSetting(
                        "size_pt", "The font's size.", .number(.pt, fontSizes, decimal: true),
                        [markEdit("editor.font-size")]),
                ]),
            CatalogTable(
                name: "editor", about: "How the editor works.",
                settings: [
                    CatalogSetting(
                        "wrap_lines", "Whether a line longer than the window wraps, at a word, or runs on.",
                        .choice([.word("never", .boolean(false)), .word("at_words", .boolean(true))]),
                        [markEdit("editor.line-wrapping")])
                ]),
            CatalogTable(
                name: "updates", about: "Whether MarkEdit looks for new versions.",
                settings: [
                    CatalogSetting(
                        "auto_check", "Whether MarkEdit checks for new versions and says when there is one.",
                        .flagAs(on: .string("notify"), off: .string("never")),
                        [.file(["settings", "general.updateBehavior"])])
                ]),
            CatalogTable(
                name: "css", about: "CSS MarkEdit adds to the editor, such as a font for code blocks.",
                settings: [
                    CatalogSetting("text", "The CSS, as it is.", .text(.plain), [.file(["css", LineBlock.textKey])])
                ]),
        ])

    // MARK: - micro

    /// The colour scheme Malum writes micro's colours into, and has micro use.
    static let microScheme = Project.command

    /// How micro names a shortcut: `Ctrl-`, `Alt-` and `Shift-` before the key, keys by micro's
    /// names, and the shortcuts a terminal sends as one control key by that key's name. A terminal
    /// can't see cmd or fn, so micro takes no shortcut that holds them.
    private static let microShortcut = ShortcutStyle.text(
        names: [.ctrl: "Ctrl", .option: "Alt", .shift: "Shift"], fn: nil, joiner: "-",
        keys: [
            "return": "Enter", "tab": "Tab", "space": "Space", "delete": "Backspace", "delete_forward": "Delete",
            "escape": "Esc", "left": "Left", "right": "Right", "up": "Up", "down": "Down", "home": "Home",
            "end": "End", "page_up": "PageUp", "page_down": "PageDown", "minus": "-", "equal": "=",
            "open_bracket": "[", "close_bracket": "]", "backslash": "\\", "semicolon": ";", "quote": "'",
            "grave": "`", "comma": ",", "period": ".", "slash": "/",
        ],
        whole: ["ctrl+slash": "CtrlUnderscore", "ctrl+backslash": "CtrlBackslash", "ctrl+space": "CtrlSpace"])

    /// The setting `name` in `[colors]`, about `about`, which colours what micro calls `group`.
    private static func microColor(_ name: String, _ group: String, _ about: String) -> CatalogSetting {
        CatalogSetting(
            name, about, .colorPair(join: ",", unset: "default"), [.file(["colorschemes", microScheme, group])])
    }

    /// The parts of micro's screen and of the text it colours, in `[colors]`.
    private static let microColors = [
        microColor("text", "default", "Plain text, and the background of the whole editor."),
        microColor("comment", "comment", "Comments."),
        microColor("identifier", "identifier", "Names of functions and other things."),
        microColor("identifier_class", "identifier.class", "Names of classes."),
        microColor("identifier_var", "identifier.var", "Names of variables."),
        microColor("constant", "constant", "Constants, such as true and false."),
        microColor("constant_number", "constant.number", "Numbers."),
        microColor("constant_string", "constant.string", "Strings."),
        microColor("symbol", "symbol", "Operators and other symbols."),
        microColor("symbol_brackets", "symbol.brackets", "Brackets."),
        microColor("symbol_tag", "symbol.tag", "Tags, such as HTML's."),
        microColor("type", "type", "Types."),
        microColor("type_keyword", "type.keyword", "Keywords that make types, such as struct."),
        microColor("type_extended", "type.extended", "Other types some languages name."),
        microColor("special", "special", "Special characters, such as escapes in a string."),
        microColor("statement", "statement", "Statements, such as if and return."),
        microColor("preprocessor", "preproc", "Preprocessor lines, such as #include."),
        microColor("underlined", "underlined", "Underlined text, such as links."),
        microColor("error", "error", "Errors in the code."),
        microColor("todo", "todo", "TODO and FIXME in comments."),
        microColor("diff_added", "diff-added", "The gutter mark of a line added since the last commit."),
        microColor("diff_modified", "diff-modified", "The gutter mark of a changed line."),
        microColor("diff_deleted", "diff-deleted", "The gutter mark where lines were removed."),
        microColor("gutter_error", "gutter-error", "The gutter mark of a line a linter finds an error in."),
        microColor("gutter_warning", "gutter-warning", "The gutter mark of a line a linter warns about."),
        microColor("status_line", "statusline", "The status line at the bottom."),
        microColor("tab_bar", "tabbar", "The tab bar at the top."),
        microColor("indent_char", "indent-char", "The marks that show indents, with indentchar set."),
        microColor("line_number", "line-number", "Line numbers."),
        microColor("current_line_number", "current-line-number", "The number of the line the cursor is on."),
        microColor("cursor_line", "cursor-line", "The line the cursor is on."),
        microColor("color_column", "color-column", "The column that marks the line length, with colorcolumn set."),
    ]

    /// `apps/micro.toml`. Malum always has micro use the colours in `[colors]`.
    static let micro = Catalog(
        file: Paths.appFile(named: "micro"),
        tables: [
            CatalogTable(
                name: "colors",
                about: "micro's colours, each a text colour and a background, with an optional style. A part "
                    + "with no text colour uses the terminal's.",
                settings: microColors),
            CatalogTable(
                name: "editor", about: "How the editor works.",
                settings: [
                    CatalogSetting(
                        "wrap_lines",
                        "Whether a line longer than the window wraps, anywhere or at a word, or runs on past the edge.",
                        .choice([
                            CatalogChoice("never", [.set(.boolean(false)), .set(.boolean(false))]),
                            CatalogChoice("anywhere", [.set(.boolean(true)), .set(.boolean(false))]),
                            CatalogChoice("at_words", [.set(.boolean(true)), .set(.boolean(true))]),
                        ]), [.file(["settings", "softwrap"]), .file(["settings", "wordwrap"])])
                ]),
            CatalogTable(
                name: "shortcuts", about: "The keys that run micro's actions.",
                settings: [
                    CatalogSetting(
                        "toggle_comment", "Comments out the selected lines, or the line the cursor is on, or back in.",
                        .shortcutKeys(microShortcut),
                        [.fileKeys(table: ["bindings"], value: .string("lua:comment.comment"))])
                ]),
            CatalogTable(
                name: "files", about: "How micro saves files.",
                settings: [
                    CatalogSetting(
                        "create_folders", "Whether saving a file makes the folders it goes in when they're missing.",
                        .flag, [.file(["settings", "mkparents"])])
                ]),
        ],
        always: [Catalog.Always(target: .file(["settings", "colorscheme"]), value: .string(microScheme))])
}
