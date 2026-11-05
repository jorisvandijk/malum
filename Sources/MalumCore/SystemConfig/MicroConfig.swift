/// micro's config, from `apps/micro.toml`. It's written to `~/.config/micro/settings.json`, with
/// `bindings.json` and one file per colour scheme in `colorschemes/` when there are any.
struct MicroConfig: AppConfig {
    /// The table of options.
    private static let settingsTable = "settings"
    /// The table of key bindings.
    private static let bindingsTable = "bindings"
    /// The table that holds one table per colour scheme.
    private static let schemesTable = "colorschemes"
    /// micro's folder, relative to the home folder.
    private static let folder = ".config/micro"
    /// The comment mark of a colour scheme file. micro's JSON files get no header.
    private static let comment = "#"
    /// How far JSON entries are indented, as micro writes them.
    private static let indent = "    "

    /// How many hex digits a `\u` escape has.
    private static let escapeDigits = 4
    /// The base of a hex number.
    private static let hexRadix = 16

    /// The app's name.
    let name = "micro"

    /// The files from `table`, and the problems found in it.
    func read(_ table: ConfigTable) -> (files: [AppFile], problems: [AppProblem]) {
        var problems = unknownKeys(table, known: [Self.settingsTable, Self.bindingsTable, Self.schemesTable])
        let settings = entries(
            table, Self.settingsTable, expected: "text, a number, true or false, or a list of text",
            problems: &problems, write: json)
        let bindings = entries(
            table, Self.bindingsTable, expected: "text in quotes, on one line", problems: &problems, write: binding)
        var files = [AppFile("\(Self.folder)/settings.json", Self.object(settings))]
        if !bindings.isEmpty {
            files.append(AppFile("\(Self.folder)/bindings.json", Self.object(bindings)))
        }
        let schemes = subtable(table, Self.schemesTable, problems: &problems)
        for scheme in schemes.keys.sorted() {
            guard let file = colorscheme(scheme, in: schemes, problems: &problems) else { continue }
            files.append(file)
        }
        return (files, problems)
    }

    /// The file of the colour scheme `scheme`: a `color-link` line for each highlight group.
    private func colorscheme(
        _ scheme: String, in schemes: ConfigTable, problems: inout [AppProblem]
    ) -> AppFile? {
        let path = [Self.schemesTable, scheme]
        guard !scheme.isEmpty, !scheme.hasPrefix("."), !scheme.contains("/") else {
            problems.append(
                AppProblem(.error, at: path, "\(dotted(path)): the name can't be empty, start with a dot or hold /"))
            return nil
        }
        let groups = entries(
            schemes, scheme, at: [Self.schemesTable], expected: "text in quotes, on one line, without \"",
            problems: &problems, write: colours)
        let lines = groups.map { "color-link \($0.key) \"\($0.value)\"\n" }.joined()
        return AppFile("\(Self.folder)/colorschemes/\(scheme).micro", header(Self.comment) + lines)
    }

    /// One key binding's action as JSON, or nil when it isn't text on one line.
    private func binding(_ value: ConfigValue) -> String? {
        line(value).map(Self.quoted)
    }

    /// One highlight group's colours, or nil when they aren't text on one line without quotes.
    private func colours(_ value: ConfigValue) -> String? {
        guard let text = line(value), !text.contains("\"") else { return nil }
        return text
    }

    /// The entries as a JSON object, one entry per line, the way micro writes its own files.
    private static func object(_ entries: [(key: String, value: String)]) -> String {
        guard !entries.isEmpty else { return "{}\n" }
        let lines = entries.map { indent + quoted($0.key) + ": " + $0.value }
        return "{\n" + lines.joined(separator: ",\n") + "\n}\n"
    }

    /// One option's value as JSON, or nil when micro has no such value.
    private func json(_ value: ConfigValue) -> String? {
        switch value {
        case .string(let text):
            Self.quoted(text)
        case .integer(let number):
            String(number)
        case .float(let number):
            number.isFinite ? String(number) : nil
        case .boolean(let flag):
            String(flag)
        case .array:
            texts(value).map { "[" + $0.map(Self.quoted).joined(separator: ", ") + "]" }
        case .date, .table:
            nil
        }
    }

    /// `text` as a JSON string, with the characters JSON needs escaped.
    private static func quoted(_ text: String) -> String {
        let escaped = text.unicodeScalars.map { scalar in
            switch scalar {
            case "\\":
                "\\\\"
            case "\"":
                "\\\""
            case "\n":
                "\\n"
            case "\t":
                "\\t"
            case _ where scalar.properties.generalCategory == .control:
                unicodeEscape(scalar)
            default:
                String(scalar)
            }
        }
        return "\"" + escaped.joined() + "\""
    }

    /// A control character as a `\uXXXX` escape.
    private static func unicodeEscape(_ scalar: Unicode.Scalar) -> String {
        let hex = String(scalar.value, radix: hexRadix)
        return "\\u" + String(repeating: "0", count: max(0, escapeDigits - hex.count)) + hex
    }
}
