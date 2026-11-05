/// An app whose config files system config writes from `apps/<name>.toml` in dots.
protocol AppConfig: Sendable {
    /// The app's name, which is also the name of its file in `apps/`.
    var name: String { get }

    /// The files the app gets from `table`, its file in `apps/`, and the problems found in it.
    func read(_ table: ConfigTable) -> (files: [AppFile], problems: [AppProblem])
}

extension AppConfig {
    /// The line at the top of each file, behind the format's comment `mark`, that says where it
    /// comes from.
    func header(_ mark: String) -> String {
        "\(mark) Written by \(Project.name) from \(Paths.appsFolderName)/\(name).toml in dots. "
            + "Changes made here are overwritten.\n"
    }

    /// A warning for each key of `table`, found at `path`, that isn't in `known`.
    func unknownKeys(_ table: ConfigTable, at path: [String] = [], known: [String]) -> [AppProblem] {
        table.keys.sorted().filter { !known.contains($0) }.map { key in
            AppProblem(.warn, at: path + [key], "unknown setting \(dotted(path + [key]))")
        }
    }

    /// `path` as a dotted key, such as `settings.user`.
    func dotted(_ path: [String]) -> String {
        path.map(ConfigValue.key).joined(separator: ".")
    }
}

// MARK: - Reading tables

extension AppConfig {
    /// The table at `key` of `table`, found at `path`, or an empty one when it's missing or isn't
    /// a table, which is an error.
    func subtable(
        _ table: ConfigTable, _ key: String, at path: [String] = [], problems: inout [AppProblem]
    ) -> ConfigTable {
        guard let value = table[key] else { return [:] }
        guard case .table(let fields) = value else {
            problems.append(AppProblem(.error, at: path + [key], "\(dotted(path + [key])) should be a table"))
            return [:]
        }
        return fields
    }

    /// The entries of the table at `key` of `table`, in alphabetical order, each value written by
    /// `write`. A value `write` turns down, by giving nil, is an error that says it should be
    /// `expected`. The apps read these as `name value` lines, so a name with a space is an error.
    func entries<Written>(
        _ table: ConfigTable, _ key: String, at path: [String] = [], expected: String,
        problems: inout [AppProblem], write: (ConfigValue) -> Written?
    ) -> [(key: String, value: Written)] {
        let fields = subtable(table, key, at: path, problems: &problems)
        return fields.sorted { $0.key < $1.key }.compactMap { entry in
            let entryPath = path + [key, entry.key]
            guard !entry.key.isEmpty, !entry.key.contains(where: \.isWhitespace) else {
                let text = "\(dotted(entryPath)): the name can't be empty or hold spaces"
                problems.append(AppProblem(.error, at: entryPath, text))
                return nil
            }
            guard let written = write(entry.value) else {
                problems.append(AppProblem(.error, at: entryPath, "\(dotted(entryPath)) should be \(expected)"))
                return nil
            }
            return (entry.key, written)
        }
    }

    /// The text in `value` when it's on one line, or nil.
    func line(_ value: ConfigValue) -> String? {
        guard case .string(let text) = value, !text.contains("\n") else { return nil }
        return text
    }

    /// The texts in `value`, or nil when it isn't a list of text.
    func texts(_ value: ConfigValue) -> [String]? {
        guard case .array(let items) = value else { return nil }
        let texts = items.compactMap { item -> String? in
            guard case .string(let text) = item else { return nil }
            return text
        }
        return texts.count == items.count ? texts : nil
    }
}
