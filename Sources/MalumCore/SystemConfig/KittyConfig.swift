/// kitty's config, from `apps/kitty.toml`. It's written to `~/.config/kitty/kitty.conf`, with the
/// colours in `~/.config/kitty/theme.conf` next to it when there are any.
struct KittyConfig: AppConfig {
    /// The table that holds the font.
    private static let fontTable = "font"
    /// The font's family, in the font table.
    private static let fontName = "name"
    /// The font's size, in the font table.
    private static let fontSize = "size"
    /// The table of colour options.
    private static let themeTable = "theme"
    /// The table of kitty.conf options.
    private static let settingsTable = "settings"
    /// The table of keyboard shortcuts.
    private static let keybindingsTable = "keybindings"
    /// kitty's folder, relative to the home folder.
    private static let folder = ".config/kitty"
    /// The file that holds the colours, next to kitty.conf.
    private static let themeFile = "theme.conf"
    /// The comment mark of kitty's config files.
    private static let comment = "#"
    /// What a value in the tables of plain text should be.
    private static let textExpected = "text in quotes, on one line"

    /// The app's name.
    let name = "kitty"

    /// The files from `table`, and the problems found in it.
    func read(_ table: ConfigTable) -> (files: [AppFile], problems: [AppProblem]) {
        var problems = unknownKeys(
            table, known: [Self.fontTable, Self.themeTable, Self.settingsTable, Self.keybindingsTable])
        let font = fontLines(table, problems: &problems)
        let theme = entries(table, Self.themeTable, expected: Self.textExpected, problems: &problems, write: line)
        let settings = entries(
            table, Self.settingsTable, expected: "text on one line, a number, true or false",
            problems: &problems, write: Self.option)
        let keys = entries(table, Self.keybindingsTable, expected: Self.textExpected, problems: &problems, write: line)
        var blocks = [font]
        var files: [AppFile] = []
        if !theme.isEmpty {
            files.append(AppFile("\(Self.folder)/\(Self.themeFile)", header(Self.comment) + Self.lines(theme)))
            blocks.append("include \(Self.themeFile)\n")
        }
        blocks.append(Self.lines(settings))
        blocks.append(Self.lines(keys.map { (key: "map \($0.key)", value: $0.value) }))
        let conf = header(Self.comment) + blocks.filter { !$0.isEmpty }.joined(separator: "\n")
        return ([AppFile("\(Self.folder)/kitty.conf", conf)] + files, problems)
    }

    /// The `font_family` and `font_size` lines from the font table.
    private func fontLines(_ table: ConfigTable, problems: inout [AppProblem]) -> String {
        let font = subtable(table, Self.fontTable, problems: &problems)
        problems += unknownKeys(font, at: [Self.fontTable], known: [Self.fontName, Self.fontSize])
        var lines: [(key: String, value: String)] = []
        if let name = font[Self.fontName] {
            if let text = line(name) {
                lines.append(("font_family", text))
            } else {
                problems.append(
                    AppProblem(.error, at: [Self.fontTable, Self.fontName], "font.name should be text in quotes"))
            }
        }
        if let size = font[Self.fontSize] {
            if let number = Self.number(size) {
                lines.append(("font_size", number))
            } else {
                problems.append(
                    AppProblem(.error, at: [Self.fontTable, Self.fontSize], "font.size should be a number"))
            }
        }
        return Self.lines(lines)
    }

    /// Each entry as a `key value` line.
    private static func lines(_ entries: [(key: String, value: String)]) -> String {
        entries.map { "\($0.key) \($0.value)\n" }.joined()
    }

    /// One kitty.conf value: text as it is, numbers, and true or false as `yes` or `no`.
    private static func option(_ value: ConfigValue) -> String? {
        switch value {
        case .string(let text):
            text.contains("\n") ? nil : text
        case .boolean(let flag):
            flag ? "yes" : "no"
        case .integer, .float:
            number(value)
        case .date, .array, .table:
            nil
        }
    }

    /// A whole number or a number with a fraction, or nil when `value` isn't a number.
    private static func number(_ value: ConfigValue) -> String? {
        switch value {
        case .integer(let number):
            String(number)
        case .float(let number):
            String(number)
        case .string, .boolean, .date, .array, .table:
            nil
        }
    }
}
