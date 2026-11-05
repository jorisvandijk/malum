/// Why the record of what Malum installed couldn't be read or written.
enum RecordError: Error, Equatable {
    /// The record's file at the path couldn't be read as a record.
    case unreadable(path: String)
    /// The record couldn't be turned into text.
    case unwritable(reason: String)
}

// MARK: - ReportableError

extension RecordError: ReportableError {
    /// The problem as the user sees it.
    var text: MessageText {
        switch self {
        case .unreadable(let path):
            "couldn't read \(private: path), the record of what \(Project.name) installed"
        case .unwritable(let reason):
            "couldn't write the record of what \(Project.name) installed: \(reason)"
        }
    }
}
