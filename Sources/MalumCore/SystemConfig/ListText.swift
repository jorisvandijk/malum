/// Files with one line per item of a list, such as git's ignore file.
enum ListText {
    /// The lines of `value`, the list found at `path`, or nil when it's missing or empty.
    static func text(_ value: ConfigValue?, at path: [String], reader: inout TableReader) -> String? {
        guard let value else { return nil }
        guard let lines = TableReader.texts(value) else {
            reader.expect(path, SettingKind.strings)
            return nil
        }
        guard !lines.isEmpty else { return nil }
        return lines.map { $0 + "\n" }.joined()
    }
}
