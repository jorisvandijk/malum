/// Why the record of what Malum installed couldn't be read.
struct RecordError: ReportableError {
    /// The problem as the user sees it.
    let text: MessageText

    /// Creates the error that says `text`.
    init(_ text: MessageText) {
        self.text = text
    }
}
