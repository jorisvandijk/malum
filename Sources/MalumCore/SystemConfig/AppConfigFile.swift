/// One config file of an app: where it goes, and the format it's written in from the app's TOML.
struct AppConfigFile: Sendable {
    /// Where the file goes, relative to the home folder. With `each`, a `*` in it is the name of
    /// the table the file is written from.
    let path: String
    /// How the file is written, and from which tables.
    let format: FileFormat
    /// Whether the file is written when its tables are empty or missing.
    let always: Bool
    /// The table that holds one table per file, such as one per colour scheme, or nil when this
    /// is a single file written from the top of the TOML.
    let each: String?

    /// Creates the file at `path`, written in `format`, which is left out when it would be empty
    /// unless it's written `always`, and written once per table in the table `each` when it's set.
    init(_ path: String, _ format: FileFormat, always: Bool = false, each: String? = nil) {
        self.path = path
        self.format = format
        self.always = always
        self.each = each
    }

    /// The tables at the top of the TOML this file reads.
    var tables: [String] {
        each.map { [$0] } ?? format.tables
    }

    /// The files written from `table`, the app's whole TOML, with each problem found added to
    /// `problems`.
    func read(_ table: ConfigTable, app: String, problems: inout [AppProblem]) -> [AppFile] {
        guard let each else {
            return file(path, from: table, at: [], app: app, problems: &problems).map { [$0] } ?? []
        }
        let tables = AppTable.subtable(table, each, at: [], problems: &problems)
        return tables.keys.sorted().compactMap { name in
            let path = [each, name]
            guard case .table(let fields)? = tables[name] else {
                problems.append(AppProblem(.error, at: path, "\(AppTable.dotted(path)) should be a table"))
                return nil
            }
            guard !name.isEmpty, !name.hasPrefix("."), !name.contains("/") else {
                let text = "\(AppTable.dotted(path)): the name can't be empty, start with a dot or hold /"
                problems.append(AppProblem(.error, at: path, text))
                return nil
            }
            let filePath = self.path.replacingOccurrences(of: "*", with: name)
            return file(filePath, from: fields, at: path, app: app, problems: &problems)
        }
    }

    /// The file at `path` written from `table`, found at `tablePath`, or nil when it would be empty
    /// and isn't written `always`.
    private func file(
        _ path: String, from table: ConfigTable, at tablePath: [String], app: String, problems: inout [AppProblem]
    ) -> AppFile? {
        let text = format.text(from: table, at: tablePath, problems: &problems)
        guard always || text != nil else { return nil }
        let header = format.comment.map { mark in
            "\(mark) Written by \(Project.name) from \(Paths.appsFolderName)/\(app).toml in dots. "
                + "Changes made here are overwritten.\n"
        }
        return AppFile(path, (header ?? "") + (text ?? format.empty))
    }
}
