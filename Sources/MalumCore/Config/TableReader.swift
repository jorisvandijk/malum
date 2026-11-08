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
        problems.sorted { ($0.line ?? Int.max) < ($1.line ?? Int.max) }
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
