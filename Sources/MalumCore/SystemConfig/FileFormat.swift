/// How a config file is written, and which tables of the app's TOML it's written from. Every app
/// shares these, so an app only says which one each of its files uses.
enum FileFormat: Sendable {
    /// A JSON object of the entries of `table`.
    case json(table: String)
    /// `name value` lines, one block of them per table, with an empty line between blocks.
    case lines([LineBlock])
    /// git's config style: a section for each table inside `table`.
    case ini(table: String)
    /// A section for each table inside `table`, headed by `keyword` and the table's name, with its
    /// `name value` lines indented, such as ssh's `Host` sections.
    case sections(table: String, keyword: String)
    /// One line for each text in the list `key` of `table`.
    case list(table: String, key: String)
    /// A feed list in newsboat's urls style, one line per feed in `table`.
    case feeds(table: String)
    /// A call per entry of `table`, such as LibreWolf's `user_pref("name", value);`.
    case calls(table: String, function: String)
    /// CSS: the `text` of `table`, as it is.
    case css(table: String)
    /// `text` as it is, the same on every Mac, read from no table.
    case fixed(String)

    /// The tables at the top of the TOML the format reads.
    var tables: [String] {
        switch self {
        case .json(let table), .ini(let table), .sections(let table, _), .list(let table, _), .feeds(let table),
            .calls(let table, _), .css(let table):
            [table]
        case .lines(let blocks):
            blocks.compactMap(\.table)
        case .fixed:
            []
        }
    }

    /// What starts and ends a comment in the format, for the line at the top that says where the
    /// file comes from, or nil when the format has no comments or the file isn't from dots.
    var comment: (start: String, end: String)? {
        switch self {
        case .json, .fixed:
            nil
        case .lines, .ini, .sections, .list, .feeds:
            ("#", "")
        case .calls:
            ("//", "")
        case .css:
            ("/*", " */")
        }
    }

    /// What a file in the format holds when there's nothing in it.
    var empty: String {
        switch self {
        case .json:
            "{}\n"
        case .lines, .ini, .sections, .list, .feeds, .calls, .css, .fixed:
            ""
        }
    }

    /// The file's text from `table`, found at `path`, or nil when there's nothing to write. Each
    /// problem found is added to `reader`.
    func text(from table: ConfigTable, at path: [String], reader: inout TableReader) -> String? {
        switch self {
        case .json(let name):
            let fields = reader.table(table, name, at: path)
            return JSONText.text(fields, at: path + [name], reader: &reader)
        case .lines(let blocks):
            var texts: [String] = []
            for block in blocks {
                let fields = block.table.map { reader.table(table, $0, at: path) } ?? table
                let blockPath = path + (block.table.map { [$0] } ?? [])
                texts += LineText.text(fields, at: blockPath, block: block, reader: &reader).map { [$0] } ?? []
            }
            return texts.isEmpty ? nil : texts.joined(separator: "\n")
        case .ini(let name):
            let fields = reader.table(table, name, at: path)
            return IniText.text(fields, at: path + [name], reader: &reader)
        case .sections(let name, let keyword):
            let fields = reader.table(table, name, at: path)
            return SectionText.text(fields, at: path + [name], keyword: keyword, reader: &reader)
        case .list(let name, let key):
            let fields = reader.table(table, name, at: path)
            reader.unknownKeys(fields, at: path + [name], known: [key])
            return ListText.text(fields[key], at: path + [name, key], reader: &reader)
        case .feeds(let name):
            let fields = reader.table(table, name, at: path)
            return FeedText.text(fields, at: path + [name], reader: &reader)
        case .calls(let name, let function):
            let fields = reader.table(table, name, at: path)
            return CallText.text(fields, at: path + [name], function: function, reader: &reader)
        case .css(let name):
            let fields = reader.table(table, name, at: path)
            return LineText.verbatim(fields, at: path + [name], reader: &reader)
        case .fixed(let text):
            return text
        }
    }
}

/// One block of `name value` lines in a file, written from one table, or the table's `text` as it is.
struct LineBlock: Sendable {
    /// How text values are written.
    enum Quoting: Sendable {
        /// As they are.
        case none
        /// In double quotes, so a shell still expands variables in them.
        case double
        /// As a shell takes them literally, in single quotes when needed.
        case shell
    }

    /// The key that holds the text of a block written as it is.
    static let textKey = "text"

    /// The table the lines come from, or nil for the table the file is written from.
    let table: String?
    /// The word written before each line, such as kitty's `map`, or nil.
    let prefix: String?
    /// What goes between a name and its value, such as `=` for a shell's `alias name=value`.
    let separator: String
    /// How text values are written.
    let quoted: Quoting
    /// Whether the block is the table's `text`, written as it is, instead of a line per entry.
    let verbatim: Bool

    /// Creates the block from `table`, with `prefix` before each line, `separator` between name and
    /// value, and text values written as `quoted` says.
    init(_ table: String?, prefix: String? = nil, separator: String = " ", quoted: Quoting = .none) {
        self.init(table, prefix: prefix, separator: separator, quoted: quoted, verbatim: false)
    }

    private init(_ table: String?, prefix: String?, separator: String, quoted: Quoting, verbatim: Bool) {
        self.table = table
        self.prefix = prefix
        self.separator = separator
        self.quoted = quoted
        self.verbatim = verbatim
    }

    /// The block written from the `text` of `table`, as it is, such as shell lines.
    static func verbatim(_ table: String) -> LineBlock {
        LineBlock(table, prefix: nil, separator: "", quoted: .none, verbatim: true)
    }
}
