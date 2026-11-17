/// JSON files, such as micro's settings: one object of the entries of a table.
enum JSONText {
    /// How far entries are indented.
    private static let indent = "    "

    /// The object from `table`, found at `path`, one entry per line, or nil when it's empty.
    static func text(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        let entries = reader.entries(table, at: path, expected: MessageText.jsonValue, write: value)
        guard !entries.isEmpty else { return nil }
        let lines = entries.map { indent + Escaping.quoted($0.key, controls: .all) + ": " + $0.value }
        return "{\n" + lines.joined(separator: ",\n") + "\n}\n"
    }

    /// One value as JSON on one line, or nil when it isn't text, a number, true or false, or a
    /// list or table of them.
    static func value(_ value: ConfigValue) -> String? {
        switch value {
        case .array(let items):
            items.map(Self.value).allPresent().map { "[" + $0.joined(separator: ", ") + "]" }
        case .table(let table):
            table.keys.sorted().map { key in
                table[key].flatMap(Self.value).map { Escaping.quoted(key, controls: .all) + ": " + $0 }
            }
            .allPresent().map { "{" + $0.joined(separator: ", ") + "}" }
        case .string, .integer, .float, .boolean, .date:
            scalar(value)
        }
    }

    /// One value as JSON, or nil when it isn't text, a number, or true or false.
    static func scalar(_ value: ConfigValue) -> String? {
        switch value {
        case .string(let text):
            Escaping.quoted(text, controls: .all)
        case .integer(let number):
            String(number)
        case .float(let number):
            number.isFinite ? String(number) : nil
        case .boolean(let flag):
            String(flag)
        case .array, .date, .table:
            nil
        }
    }
}
