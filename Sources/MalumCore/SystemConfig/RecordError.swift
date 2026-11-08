/// Why the record of what Malum installed couldn't be read or written.
enum RecordError: Error, Equatable {
    /// The record's file at the path couldn't be read as a record.
    case unreadable(path: String)
    /// The record couldn't be turned into text.
    case unwritable(reason: String)
    /// The record's text isn't UTF-8.
    case notUTF8
}
