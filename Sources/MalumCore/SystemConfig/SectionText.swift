/// Files of sections that each start with a keyword and a name, followed by indented `name value`
/// lines, such as ssh's `Host github.com`.
enum SectionText {
    /// The characters that make a section's name a pattern, which goes after the plain names so a
    /// plain one matches first.
    private static let patternMarks: Set<Character> = ["*", "?", "!"]

    /// The sections from `table`, found at `path`, one for each table in it, each headed by
    /// `keyword` and its name, or nil when there are none. Plain names come first, then patterns
    /// such as `*`, each in alphabetical order.
    static func text(_ table: ConfigTable, at path: [String], keyword: String, reader: inout TableReader) -> String? {
        var text: [String] = []
        for (name, entries) in table.sorted(by: inOrder) {
            guard let entries = reader.table(entries, at: path + [name]) else { continue }
            let lines = LineText.text(entries, at: path + [name], block: LineBlock(nil), reader: &reader) ?? ""
            let indented = lines.split(separator: "\n").map { "  \($0)\n" }.joined()
            text.append("\(keyword) \(name)\n\(indented)")
        }
        return text.isEmpty ? nil : text.joined(separator: "\n")
    }

    /// Whether the section `first` goes before `second`: a plain name before a pattern, and then
    /// by name.
    private static func inOrder(_ first: (key: String, value: ConfigValue), _ second: (key: String, value: ConfigValue))
        -> Bool
    {
        let firstIsPattern = first.key.contains(where: patternMarks.contains)
        guard firstIsPattern == second.key.contains(where: patternMarks.contains) else { return !firstIsPattern }
        return first.key < second.key
    }
}
