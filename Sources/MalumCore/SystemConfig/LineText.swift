/// Files of `name value` lines, such as kitty's config.
enum LineText {
    /// The lines from `table`, found at `path`, as `block` asks, or nil when there are none.
    static func text(
        _ table: ConfigTable, at path: [String], block: LineBlock, reader: inout TableReader
    ) -> String? {
        var named: ConfigTable = [:]
        for (name, value) in table.sorted(by: { $0.key < $1.key }) {
            guard !name.isEmpty, !name.contains(where: \.isWhitespace) else {
                reader.add(
                    .error, at: path + [name],
                    "\(TableReader.dotted(path + [name])): the name can't be empty or hold spaces")
                continue
            }
            named[name] = value
        }
        let entries = reader.entries(named, at: path, expected: "text on one line, a number, true or false") {
            value(of: $0, quoted: block.quoted)
        }
        guard !entries.isEmpty else { return nil }
        let prefix = block.prefix.map { $0 + " " } ?? ""
        return entries.map { "\(prefix)\($0.key) \($0.value)\n" }.joined()
    }

    /// One value: text, in quotes when `quoted`, numbers, and true or false as `yes` or `no`, or
    /// nil when it's none of those or text over more than one line.
    private static func value(of value: ConfigValue, quoted: Bool) -> String? {
        switch value {
        case .string(let text):
            guard !text.contains("\n") else { return nil }
            return quoted ? self.quoted(text) : text
        case .integer(let number):
            return String(number)
        case .float(let number):
            return String(number)
        case .boolean(let flag):
            return flag ? "yes" : "no"
        case .date, .array, .table:
            return nil
        }
    }

    /// `text` in double quotes, with backslashes and quotes escaped.
    private static func quoted(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}
