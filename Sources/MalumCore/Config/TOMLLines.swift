import Foundation

/// The line each table and key starts on in TOML text, since the parser doesn't keep them.
///
/// It only reads text the parser has already accepted, so a simple scan is enough. Keys inside
/// inline tables and multi-line arrays aren't found; the line of their nearest named parent is used.
struct TOMLLines {
    /// The marks that open and close a multi-line string.
    private static let multiLineQuotes = ["\"\"\"", "'''"]

    /// Quote marks come in pairs, so an odd number of them on a line opens or closes a string.
    private static let pair = 2

    /// The first line of each table and key, by its path from the top.
    private var lines: [[String]: Int] = [:]
    /// The path of the table that the lines being read belong to.
    private var table: [String] = []
    /// The mark that ends the multi-line string being read, if inside one.
    private var openString: String?

    /// Scans `text`.
    init(_ text: String) {
        let rows = text.split(separator: "\n", omittingEmptySubsequences: false)
        for (offset, row) in rows.enumerated() {
            scan(String(row), number: offset + 1)
        }
    }

    /// The line `path` starts on, or the line of its nearest parent that's found.
    func line(of path: [String]) -> Int? {
        var path = path
        while !path.isEmpty {
            if let line = lines[path] { return line }
            path.removeLast()
        }
        return nil
    }

    /// Records the table header or key on one line.
    private mutating func scan(_ row: String, number: Int) {
        if let mark = openString {
            if Self.isOdd(Self.count(of: mark, in: row)) { openString = nil }
            return
        }
        let line = row.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("[") {
            header(line, number: number)
            return
        }
        guard let equals = line.firstIndex(of: "="), let key = Self.keyPath(line[..<equals]) else { return }
        record(table + key, number: number)
        let value = line[line.index(after: equals)...]
        openString = Self.multiLineQuotes.first { Self.isOdd(Self.count(of: $0, in: value)) }
    }

    /// Starts a new table at a `[table]` or `[[array of tables]]` header.
    private mutating func header(_ line: String, number: Int) {
        let name = line.drop { $0 == "[" }.prefix { $0 != "]" }
        guard let path = Self.keyPath(name) else { return }
        table = path
        record(path, number: number)
    }

    /// Keeps the first line a path is seen on.
    private mutating func record(_ path: [String], number: Int) {
        guard lines[path] == nil else { return }
        lines[path] = number
    }

    /// The parts of a dotted key such as `window_manager.gap` or `"a b".c`, or nil when it isn't one.
    private static func keyPath(_ text: Substring) -> [String]? {
        let parts = parts(of: text).map { $0.trimmingCharacters(in: .whitespaces) }
        let keys = parts.compactMap(key)
        return keys.count == parts.count && !keys.isEmpty ? keys : nil
    }

    /// `text` split at each dot outside quotes, so `"com.apple.dock".x` is two parts.
    private static func parts(of text: Substring) -> [String] {
        var parts = [""]
        var quote: Character?
        for character in text {
            switch character {
            case "." where quote == nil:
                parts.append("")
                continue
            case "\"", "'":
                quote = quote == nil ? character : (quote == character ? nil : quote)
            default:
                break
            }
            parts[parts.count - 1].append(character)
        }
        return parts
    }

    /// One part of a key, without its quotes, or nil when it isn't a key.
    private static func key(_ part: String) -> String? {
        for quote in ["\"", "'"] where part.count > 1 && part.hasPrefix(quote) && part.hasSuffix(quote) {
            return String(part.dropFirst().dropLast())
        }
        let bare = part.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        return bare && !part.isEmpty ? part : nil
    }

    /// Whether `count` marks leave a string opened or closed.
    private static func isOdd(_ count: Int) -> Bool {
        !count.isMultiple(of: pair)
    }

    /// How often `mark` appears in `text`.
    private static func count(of mark: String, in text: some StringProtocol) -> Int {
        text.components(separatedBy: mark).count - 1
    }
}
