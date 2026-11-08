/// Files of `name value` lines, such as kitty's config, and text written as it is, such as shell
/// lines.
enum LineText {
    /// The lines from `table`, found at `path`, as `block` asks, or nil when there are none. A
    /// list writes its name once for each item.
    static func text(
        _ table: ConfigTable, at path: [String], block: LineBlock, reader: inout TableReader
    ) -> String? {
        guard !block.verbatim else { return verbatim(table, at: path, reader: &reader) }
        let prefix = block.prefix.map { $0 + " " } ?? ""
        var lines: [String] = []
        for (name, value) in table.sorted(by: { $0.key < $1.key }) {
            guard !name.isEmpty, !name.contains(where: \.isWhitespace) else {
                reader.add(.error, at: path + [name], .notLineName(TableReader.dotted(path + [name])))
                continue
            }
            let written = value.items.compactMap { self.value(of: $0, quoted: block.quoted) }
            guard written.count == value.items.count else {
                reader.expect(path + [name], MessageText.lineValue)
                continue
            }
            lines += written.map { "\(prefix)\(name)\(block.separator)\($0)\n" }
        }
        return lines.isEmpty ? nil : lines.joined()
    }

    /// The `text` of `table`, found at `path`, ending in a line break, or nil when there's none.
    static func verbatim(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        reader.unknownKeys(table, at: path, known: [LineBlock.textKey])
        guard let value = table[LineBlock.textKey] else { return nil }
        guard case .string(let text) = value else {
            reader.expect(path + [LineBlock.textKey], SettingKind.string)
            return nil
        }
        guard !text.isEmpty else { return nil }
        return text.hasSuffix("\n") ? text : text + "\n"
    }

    /// One value: text, quoted as `quoted` says, numbers, and true or false as `yes` or `no`, or
    /// nil when it's none of those or text over more than one line.
    private static func value(of value: ConfigValue, quoted: LineBlock.Quoting) -> String? {
        switch value {
        case .string(let text):
            guard !text.contains("\n") else { return nil }
            switch quoted {
            case .none:
                return text
            case .double:
                return Escaping.quoted(text, controls: .none)
            case .shell:
                return Escaping.shell(text)
            }
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
