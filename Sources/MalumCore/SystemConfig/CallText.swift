/// Files of one call per entry, such as LibreWolf's `user.js`: `user_pref("name", value);`, the
/// value written as JSON.
enum CallText {
    /// The calls to `function` from `table`, found at `path`, one per line, or nil when there are
    /// none.
    static func text(_ table: ConfigTable, at path: [String], function: String, reader: inout TableReader) -> String? {
        let entries = reader.entries(
            table, at: path, expected: "text, a number, or true or false", write: JSONText.scalar)
        guard !entries.isEmpty else { return nil }
        return entries.map { "\(function)(\(Escaping.quoted($0.key, controls: .all)), \($0.value));\n" }.joined()
    }
}
