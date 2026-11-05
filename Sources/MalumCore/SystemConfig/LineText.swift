/// Files of `name value` lines, such as kitty's config.
enum LineText {
    /// The lines from `table`, found at `path`, as `block` asks, or nil when there are none. A
    /// list writes its name once for each item.
    static func text(
        _ table: ConfigTable, at path: [String], block: LineBlock, reader: inout TableReader
    ) -> String? {
        let prefix = block.prefix.map { $0 + " " } ?? ""
        var lines: [String] = []
        for (name, value) in table.sorted(by: { $0.key < $1.key }) {
            guard !name.isEmpty, !name.contains(where: \.isWhitespace) else {
                reader.add(
                    .error, at: path + [name],
                    "\(TableReader.dotted(path + [name])): the name can't be empty or hold spaces")
                continue
            }
            let written = value.items.compactMap { self.value(of: $0, quoted: block.quoted) }
            guard written.count == value.items.count else {
                reader.expect(path + [name], "text on one line, a number, true or false, or a list of them")
                continue
            }
            lines += written.map { "\(prefix)\(name) \($0)\n" }
        }
        return lines.isEmpty ? nil : lines.joined()
    }

    /// One value: text, in quotes when `quoted`, numbers, and true or false as `yes` or `no`, or
    /// nil when it's none of those or text over more than one line.
    private static func value(of value: ConfigValue, quoted: Bool) -> String? {
        switch value {
        case .string(let text):
            guard !text.contains("\n") else { return nil }
            return quoted ? Escaping.quoted(text, controls: .none) : text
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
}
