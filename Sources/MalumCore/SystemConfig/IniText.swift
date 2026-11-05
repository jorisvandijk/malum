/// Files in git's config style: `[section]` headers, each followed by `key = value` lines.
enum IniText {
    /// The sections from `table`, found at `path`, one for each table in it in alphabetical order,
    /// or nil when there are none.
    static func text(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        var text: [String] = []
        for (name, entries) in table.sorted(by: { $0.key < $1.key }) {
            guard let entries = reader.table(entries, at: path + [name]) else { continue }
            text.append(section(name, entries, at: path + [name], reader: &reader))
        }
        return text.isEmpty ? nil : text.joined(separator: "\n")
    }

    /// One section, found at `path`, with its keys in alphabetical order. A list writes its key
    /// once for each item.
    private static func section(
        _ name: String, _ entries: ConfigTable, at path: [String], reader: inout TableReader
    ) -> String {
        var text = "[\(sectionName(name))]\n"
        for (key, value) in entries.sorted(by: { $0.key < $1.key }) {
            let items: [ConfigValue]
            if case .array(let list) = value { items = list } else { items = [value] }
            let written = items.compactMap(self.value)
            guard written.count == items.count else {
                reader.expect(path + [key], "text, a whole number, true or false, or a list of them")
                continue
            }
            text += written.map { "\t\(key) = \($0)\n" }.joined()
        }
        return text
    }

    /// A section's header name. A dot names a subsection, so `url.git@github.com:` becomes
    /// `url "git@github.com:"`.
    private static func sectionName(_ name: String) -> String {
        guard !name.contains("\""), let dot = name.firstIndex(of: ".") else { return name }
        return "\(name[..<dot]) \"\(name[name.index(after: dot)...])\""
    }

    /// One value, with text in quotes, or nil when the format has no such value.
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

    /// `text` with the characters a quoted value needs escaped.
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
