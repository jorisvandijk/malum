/// git's settings, from `apps/git.toml`. They're written to `~/.config/git/config`, with
/// `~/.config/git/ignore` and `~/.config/git/attributes` next to it when those are listed.
struct GitConfig: AppConfig {
    /// The table that holds git's config, one table inside it per section.
    private static let settingsTable = "settings"
    /// The table that lists what git ignores everywhere.
    private static let ignoreTable = "ignore"
    /// The list in the ignore table.
    private static let ignoreKey = "patterns"
    /// The table that lists attributes for every repository.
    private static let attributesTable = "attributes"
    /// The list in the attributes table.
    private static let attributesKey = "lines"
    /// git's folder, relative to the home folder.
    private static let folder = ".config/git"
    /// The comment mark of every file git reads.
    private static let comment = "#"

    /// The app's name.
    let name = "git"

    /// The files from `table`, and the problems found in it.
    func read(_ table: ConfigTable) -> (files: [AppFile], problems: [AppProblem]) {
        var problems = unknownKeys(table, known: [Self.settingsTable, Self.ignoreTable, Self.attributesTable])
        let config = settings(table[Self.settingsTable], problems: &problems)
        let ignore = list(table, Self.ignoreTable, Self.ignoreKey, problems: &problems)
        let attributes = list(table, Self.attributesTable, Self.attributesKey, problems: &problems)
        var files = [AppFile("\(Self.folder)/config", header(Self.comment) + config)]
        for (fileName, lines) in [(Self.ignoreTable, ignore), (Self.attributesTable, attributes)] where !lines.isEmpty {
            files.append(AppFile("\(Self.folder)/\(fileName)", header(Self.comment) + lines.map { $0 + "\n" }.joined()))
        }
        return (files, problems)
    }

    /// git's config file from the settings table: one section for each table in it, in
    /// alphabetical order.
    private func settings(_ value: ConfigValue?, problems: inout [AppProblem]) -> String {
        guard let value else { return "" }
        guard case .table(let sections) = value else {
            problems.append(AppProblem(.error, at: [Self.settingsTable], "\(Self.settingsTable) should be a table"))
            return ""
        }
        var text: [String] = []
        for (section, entries) in sections.sorted(by: { $0.key < $1.key }) {
            let path = [Self.settingsTable, section]
            guard case .table(let entries) = entries else {
                problems.append(AppProblem(.error, at: path, "\(dotted(path)) should be a table"))
                continue
            }
            text.append(self.section(section, entries, problems: &problems))
        }
        return text.joined(separator: "\n")
    }

    /// One section of git's config, with its keys in alphabetical order. A list writes its key
    /// once for each item.
    private func section(_ name: String, _ entries: ConfigTable, problems: inout [AppProblem]) -> String {
        var text = "[\(Self.sectionName(name))]\n"
        for (key, value) in entries.sorted(by: { $0.key < $1.key }) {
            let items: [ConfigValue]
            if case .array(let list) = value { items = list } else { items = [value] }
            let written = items.compactMap(Self.value)
            guard written.count == items.count else {
                let path = [Self.settingsTable, name, key]
                problems.append(
                    AppProblem(
                        .error, at: path,
                        "\(dotted(path)) should be text, a whole number, true or false, or a list of them"))
                continue
            }
            text += written.map { "\t\(key) = \($0)\n" }.joined()
        }
        return text
    }

    /// The text lines in `key` of the table `name`.
    private func list(
        _ table: ConfigTable, _ name: String, _ key: String, problems: inout [AppProblem]
    ) -> [String] {
        guard let value = table[name] else { return [] }
        guard case .table(let fields) = value else {
            problems.append(AppProblem(.error, at: [name], "\(name) should be a table"))
            return []
        }
        problems += unknownKeys(fields, at: [name], known: [key])
        guard let items = fields[key] else { return [] }
        let lines = Self.texts(items)
        guard let lines else {
            problems.append(AppProblem(.error, at: [name, key], "\(name).\(key) should be a list of text in quotes"))
            return []
        }
        return lines
    }

    /// The texts in `value`, or nil when it isn't a list of them.
    private static func texts(_ value: ConfigValue) -> [String]? {
        guard case .array(let items) = value else { return nil }
        let texts = items.compactMap { item -> String? in
            guard case .string(let text) = item else { return nil }
            return text
        }
        return texts.count == items.count ? texts : nil
    }

    /// A section's header name. A dot names a subsection, so `url.git@github.com:` becomes
    /// `url "git@github.com:"`.
    private static func sectionName(_ name: String) -> String {
        guard !name.contains("\""), let dot = name.firstIndex(of: ".") else { return name }
        return "\(name[..<dot]) \"\(name[name.index(after: dot)...])\""
    }

    /// One value as git's config writes it, with text in quotes, or nil when git has no such value.
    private static func value(_ value: ConfigValue) -> String? {
        switch value {
        case .string(let text):
            "\"" + escaped(text) + "\""
        case .integer(let number):
            String(number)
        case .boolean(let flag):
            String(flag)
        case .float, .date, .array, .table:
            nil
        }
    }

    /// `text` with the characters git's quoted values need escaped.
    private static func escaped(_ text: String) -> String {
        text.unicodeScalars.map { scalar in
            switch scalar {
            case "\\":
                "\\\\"
            case "\"":
                "\\\""
            case "\n":
                "\\n"
            case "\t":
                "\\t"
            default:
                String(scalar)
            }
        }.joined()
    }
}
