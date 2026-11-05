/// How a config file is written, and which tables of the app's TOML it's written from. Every app
/// shares these, so an app only says which one each of its files uses.
enum FileFormat: Sendable {
    /// A JSON object of the entries of `table`.
    case json(table: String)
    /// `name value` lines, one block of them per table, with an empty line between blocks.
    case lines([LineBlock])
    /// git's config style: a section for each table inside `table`.
    case ini(table: String)
    /// One line for each text in the list `key` of `table`.
    case list(table: String, key: String)

    /// The tables at the top of the TOML the format reads.
    var tables: [String] {
        switch self {
        case .json(let table), .ini(let table), .list(let table, _):
            [table]
        case .lines(let blocks):
            blocks.compactMap(\.table)
        }
    }

    /// The comment mark of the format, for the line at the top that says where the file comes
    /// from, or nil when the format has no comments.
    var comment: String? {
        switch self {
        case .json:
            nil
        case .lines, .ini, .list:
            "#"
        }
    }

    /// What a file in the format holds when there's nothing in it.
    var empty: String {
        switch self {
        case .json:
            "{}\n"
        case .lines, .ini, .list:
            ""
        }
    }

    /// The file's text from `table`, found at `path`, or nil when there's nothing to write. Each
    /// problem found is added to `problems`.
    func text(from table: ConfigTable, at path: [String], problems: inout [AppProblem]) -> String? {
        switch self {
        case .json(let name):
            let fields = AppTable.subtable(table, name, at: path, problems: &problems)
            return JSONText.text(fields, at: path + [name], problems: &problems)
        case .lines(let blocks):
            var texts: [String] = []
            for block in blocks {
                let fields = block.table.map { AppTable.subtable(table, $0, at: path, problems: &problems) } ?? table
                let blockPath = path + (block.table.map { [$0] } ?? [])
                texts += LineText.text(fields, at: blockPath, block: block, problems: &problems).map { [$0] } ?? []
            }
            return texts.isEmpty ? nil : texts.joined(separator: "\n")
        case .ini(let name):
            let fields = AppTable.subtable(table, name, at: path, problems: &problems)
            return IniText.text(fields, at: path + [name], problems: &problems)
        case .list(let name, let key):
            let fields = AppTable.subtable(table, name, at: path, problems: &problems)
            problems += AppTable.unknownKeys(fields, at: path + [name], known: [key])
            return ListText.text(fields[key], at: path + [name, key], problems: &problems)
        }
    }
}

/// One block of `name value` lines in a file, written from one table.
struct LineBlock: Sendable {
    /// The table the lines come from, or nil for the table the file is written from.
    let table: String?
    /// The word written before each line, such as kitty's `map`, or nil.
    let prefix: String?
    /// Whether text values are written in double quotes.
    let quoted: Bool

    /// Creates the block from `table`, with `prefix` before each line and text values `quoted`.
    init(_ table: String?, prefix: String? = nil, quoted: Bool = false) {
        self.table = table
        self.prefix = prefix
        self.quoted = quoted
    }
}
