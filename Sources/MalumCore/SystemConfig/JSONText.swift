/// JSON files, such as micro's settings: one object of the entries of a table.
enum JSONText {
    /// How far entries are indented.
    private static let indent = "    "

    /// The object from `table`, found at `path`, one entry per line, or nil when it's empty.
    static func text(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        let entries = reader.entries(
            table, at: path, expected: "text, a number, true or false, or a list of them", write: value)
        guard !entries.isEmpty else { return nil }
        let lines = entries.map { indent + Escaping.quoted($0.key, controls: .all) + ": " + $0.value }
        return "{\n" + lines.joined(separator: ",\n") + "\n}\n"
    }

    /// One value as JSON, or nil when it isn't text, a number, true or false, or a list of them.
    private static func value(_ value: ConfigValue) -> String? {
        guard case .array(let items) = value else { return scalar(value) }
        return list(items)
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

    /// `items` as a JSON list on one line, or nil when one of them isn't text, a number, or true
    /// or false.
    private static func list(_ items: [ConfigValue]) -> String? {
        let written = items.compactMap(scalar)
        guard written.count == items.count else { return nil }
        return "[" + written.joined(separator: ", ") + "]"
    }
}
