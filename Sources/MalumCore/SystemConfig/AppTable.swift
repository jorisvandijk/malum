/// Reading the tables of an app's file in `apps/`, reporting what's wrong with the key it's at.
enum AppTable {
    /// The table at `key` of `table`, found at `path`, or an empty one when it's missing or isn't
    /// a table, which is an error.
    static func subtable(
        _ table: ConfigTable, _ key: String, at path: [String], problems: inout [AppProblem]
    ) -> ConfigTable {
        guard let value = table[key] else { return [:] }
        guard case .table(let fields) = value else {
            problems.append(AppProblem(.error, at: path + [key], "\(dotted(path + [key])) should be a table"))
            return [:]
        }
        return fields
    }

    /// The entries of `table`, found at `path`, in alphabetical order, each value written by
    /// `write`. A value `write` turns down, by giving nil, is an error that says it should be
    /// `expected`.
    static func entries(
        _ table: ConfigTable, at path: [String], expected: String, problems: inout [AppProblem],
        write: (ConfigValue) -> String?
    ) -> [(key: String, value: String)] {
        table.sorted { $0.key < $1.key }.compactMap { entry in
            guard let written = write(entry.value) else {
                let entryPath = path + [entry.key]
                problems.append(AppProblem(.error, at: entryPath, "\(dotted(entryPath)) should be \(expected)"))
                return nil
            }
            return (entry.key, written)
        }
    }

    /// A warning for each key of `table`, found at `path`, that isn't in `known`.
    static func unknownKeys(_ table: ConfigTable, at path: [String], known: [String]) -> [AppProblem] {
        table.keys.sorted().filter { !known.contains($0) }.map { key in
            AppProblem(.warn, at: path + [key], "unknown setting \(dotted(path + [key]))")
        }
    }

    /// The texts in `value`, or nil when it isn't a list of text.
    static func texts(_ value: ConfigValue) -> [String]? {
        guard case .array(let items) = value else { return nil }
        let texts = items.compactMap { item -> String? in
            guard case .string(let text) = item else { return nil }
            return text
        }
        return texts.count == items.count ? texts : nil
    }

    /// `path` as a dotted key, such as `settings.user`.
    static func dotted(_ path: [String]) -> String {
        path.map(ConfigValue.key).joined(separator: ".")
    }
}
