/// JSON files, such as micro's settings: one object of the entries of a table.
enum JSONText {
    /// How far entries are indented.
    private static let indent = "    "
    /// How many hex digits a `\u` escape has.
    private static let escapeDigits = 4
    /// The base of a hex number.
    private static let hexRadix = 16

    /// The object from `table`, found at `path`, one entry per line, or nil when it's empty.
    static func text(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        let entries = reader.entries(
            table, at: path, expected: "text, a number, true or false, or a list of them", write: value)
        guard !entries.isEmpty else { return nil }
        let lines = entries.map { indent + quoted($0.key) + ": " + $0.value }
        return "{\n" + lines.joined(separator: ",\n") + "\n}\n"
    }

    /// One value as JSON, or nil when it isn't text, a number, true or false, or a list of them.
    private static func value(_ value: ConfigValue) -> String? {
        switch value {
        case .string(let text):
            quoted(text)
        case .integer(let number):
            String(number)
        case .float(let number):
            number.isFinite ? String(number) : nil
        case .boolean(let flag):
            String(flag)
        case .array(let items):
            list(items)
        case .date, .table:
            nil
        }
    }

    /// `items` as a JSON list on one line, or nil when one of them is a list or isn't a value.
    private static func list(_ items: [ConfigValue]) -> String? {
        let written = items.compactMap { item -> String? in
            guard case .array = item else { return value(item) }
            return nil
        }
        guard written.count == items.count else { return nil }
        return "[" + written.joined(separator: ", ") + "]"
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
