/// Feed lists in newsboat's urls style: one line per feed, its address, then its tags and its
/// title in quotes.
enum FeedText {
    /// The fields a feed's table holds.
    private static let fields = ["url", "tags"]

    /// The lines from `table`, one per feed, found at `path`, in alphabetical order of title, or
    /// nil when there are none.
    static func text(_ table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        let titles = table.keys.sorted { ($0.lowercased(), $0) < ($1.lowercased(), $1) }
        var lines: [String] = []
        for title in titles {
            guard let value = table[title], let words = feed(value, at: path + [title], reader: &reader) else {
                continue
            }
            let quoted = (words.tags + ["~" + title]).map { Escaping.quoted($0, controls: .breaks) }
            lines.append(([words.url] + quoted).joined(separator: " ") + "\n")
        }
        return lines.isEmpty ? nil : lines.joined()
    }

    /// A feed's address and tags, from `"address"` or `{ url = "address", tags = [...] }`, found at
    /// `path`, or nil and an error when it's neither.
    private static func feed(
        _ value: ConfigValue, at path: [String], reader: inout TableReader
    ) -> (url: String, tags: [String])? {
        var fields: ConfigTable = ["url": value]
        if case .table(let table) = value {
            reader.unknownKeys(table, at: path, known: Self.fields)
            fields = table
        }
        guard case .string(let url)? = fields["url"], !url.isEmpty, !url.contains(where: \.isWhitespace) else {
            reader.expect(path, MessageText.feedValue)
            return nil
        }
        guard let tags = fields["tags"] else { return (url, []) }
        guard let texts = TableReader.texts(tags) else {
            reader.expect(path + ["tags"], SettingKind.strings)
            return nil
        }
        return (url, texts)
    }
}
