import TOMLKit

/// Turns TOML text into a table, or a syntax error that says where the problem is.
public enum TOMLReader {
    /// Parses `text`, throwing a `TOMLReadError` with the line and column of a syntax error.
    public static func table(from text: String) throws(TOMLReadError) -> TOMLTable {
        do {
            return try TOMLTable(string: text)
        } catch let error as TOMLParseError {
            throw .syntax(
                line: error.source.begin.line, column: error.source.begin.column, reason: error.description)
        } catch {
            throw .unreadable(reason: String(describing: error))
        }
    }
}
