/// One of Malum's TOML files in dots, parsed, with what's wrong in it so far. Each problem it
/// collects is at the line of the key it's about.
struct TableReader {
    /// The file's name as problems show it, such as `packages.toml`.
    let file: String
    /// The whole file.
    let document: ConfigTable
    /// The line each key is on.
    private let lines: TOMLLines
    /// What's wrong so far, in the order it was found.
    private(set) var problems: [ConfigProblem] = []

    /// Called each time a reader checks a table for keys it doesn't know, with the table's path, the
    /// keys it takes and the table. Only the test that every key has docs sets it.
    @TaskLocal static var onKnownKeys: (@Sendable ([String], [String], ConfigTable) -> Void)?

    /// Parses `text`, the file `file`. A syntax error is thrown as a problem at its line and column.
    init(_ text: String, file: String) throws(ConfigProblem) {
        self.file = file
        do {
            document = ConfigValue.table(try TOMLReader.table(from: text))
        } catch {
            switch error {
            case .syntax(let line, let column, let reason):
                throw ConfigProblem(.error, file: file, line: line, column: column, MessageText(reason))
            case .unreadable(let reason):
                throw ConfigProblem(.error, file: file, .unreadable(file, reason))
            }
        }
        lines = TOMLLines(text)
    }

    /// The problems so far, in the order of their lines, those without a line last.
    var problemsByLine: [ConfigProblem] {
        ConfigProblem.byLine(problems)
    }

    /// Whether any problem so far is an error.
    var hasErrors: Bool { problems.contains { $0.level == .error } }

    /// Adds a problem of `level` about the key `path`.
    mutating func add(_ level: Level, at path: [String], _ text: MessageText) {
        problems.append(ConfigProblem(level, file: file, line: lines.line(of: path), text))
    }

    /// Adds the error that the key `path` should be `expected`, such as `SettingKind.string`.
    mutating func expect(_ path: [String], _ expected: some CustomStringConvertible) {
        add(.error, at: path, .shouldBe(Self.dotted(path), expected))
    }

    /// The table in `value`, found at `path`, or nil and an error when it isn't one.
    mutating func table(_ value: ConfigValue, at path: [String]) -> ConfigTable? {
        guard case .table(let fields) = value else {
            expect(path, SettingKind.table)
            return nil
        }
        return fields
    }

    /// The table at `key` of `table`, found at `path`, or an empty one when it's missing or isn't
    /// a table, which is an error.
    mutating func table(_ table: ConfigTable, _ key: String, at path: [String]) -> ConfigTable {
        guard let value = table[key] else { return [:] }
        return self.table(value, at: path + [key]) ?? [:]
    }

    /// The value of `key` in the file's table `table`, or nil when either is missing, with a warning
    /// for each other key in that table. For tables that hold one setting.
    mutating func onlyKey(_ key: String, of table: String) -> ConfigValue? {
        let fields = self.table(document, table, at: [])
        unknownKeys(fields, at: [table], known: [key])
        return fields[key]
    }

    /// The list of text `key` in the file's table `table`, which holds one setting, or none when it's
    /// left out or wrong. An item `check` turns down is an error worded by `problem` from the key's path.
    mutating func onlyList(
        _ key: String, of table: String, check: (String) -> Bool, problem: (String) -> MessageText
    ) -> [String] {
        guard let value = onlyKey(key, of: table) else { return [] }
        let path = [table, key]
        guard let items = Self.texts(value) else {
            expect(path, SettingKind.strings)
            return []
        }
        guard items.allSatisfy(check) else {
            add(.error, at: path, problem(Self.dotted(path)))
            return []
        }
        return items
    }

    /// The switch `key` of `table`, found at `path`, or nil when it's left out or isn't one, which
    /// is an error.
    mutating func flag(_ table: ConfigTable, _ key: String, at path: [String]) -> Bool? {
        guard let value = table[key] else { return nil }
        guard case .boolean(let isOn) = value else {
            expect(path + [key], SettingKind.boolean)
            return nil
        }
        return isOn
    }

    /// The text `key` of `table`, found at `path`, or nil when it's left out or isn't text, which
    /// is an error.
    mutating func text(_ table: ConfigTable, _ key: String, at path: [String]) -> String? {
        guard let value = table[key] else { return nil }
        guard case .string(let text) = value else {
            expect(path + [key], SettingKind.string)
            return nil
        }
        return text
    }

    /// The list of text `key` of `table`, found at `path`, or nil when it's left out or isn't one,
    /// which is an error.
    mutating func texts(_ table: ConfigTable, _ key: String, at path: [String]) -> [String]? {
        guard let value = table[key] else { return nil }
        guard let texts = Self.texts(value) else {
            expect(path + [key], SettingKind.strings)
            return nil
        }
        return texts
    }

    /// The entries of `table`, found at `path`, in alphabetical order, each value written by
    /// `write`. A value `write` turns down, by giving nil, is an error that says it should be
    /// `expected`, such as `SettingKind.string`.
    mutating func entries(
        _ table: ConfigTable, at path: [String], expected: some CustomStringConvertible,
        write: (ConfigValue) -> String?
    ) -> [(key: String, value: String)] {
        table.sorted { $0.key < $1.key }.compactMap { entry in
            guard let written = write(entry.value) else {
                expect(path + [entry.key], expected)
                return nil
            }
            return (entry.key, written)
        }
    }

    /// Adds a warning for each key of `table`, found at `path`, that isn't in `known`.
    mutating func unknownKeys(_ table: ConfigTable, at path: [String], known: [String]) {
        Self.onKnownKeys?(path, known, table)
        for key in table.keys.sorted() where !known.contains(key) {
            let isTable = if case .table? = table[key] { true } else { false }
            add(.warn, at: path + [key], .unknownKey(Self.dotted(path + [key]), isTable: isTable))
        }
    }

    /// The texts in `value`, or nil when it isn't a list of text.
    static func texts(_ value: ConfigValue) -> [String]? {
        guard case .array(let items) = value else { return nil }
        let texts = items.compactMap { item -> String? in
            guard case .string(let text) = item else { return nil }
            return text
        }
        return texts.count == items.count ? texts : nil
    }

    /// `path` as a dotted key, such as `settings.user`.
    static func dotted(_ path: [String]) -> String {
        path.map(ConfigValue.key).joined(separator: ".")
    }
}
