/// Files with one line per item of a list, such as git's ignore file.
enum ListText {
    /// The lines of `value`, the list found at `path`, or nil when it's missing or empty.
    static func text(_ value: ConfigValue?, at path: [String], problems: inout [AppProblem]) -> String? {
        guard let value else { return nil }
        guard let lines = AppTable.texts(value) else {
            problems.append(
                AppProblem(.error, at: path, "\(AppTable.dotted(path)) should be a list of text in quotes"))
            return nil
        }
        guard !lines.isEmpty else { return nil }
        return lines.map { $0 + "\n" }.joined()
    }
}
