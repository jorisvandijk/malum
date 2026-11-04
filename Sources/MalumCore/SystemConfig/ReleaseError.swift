/// Why one GitHub release couldn't be installed.
struct ReleaseError: ReportableError {
    /// The problem as the user sees it.
    let text: MessageText

    /// Creates the error that says `text`.
    init(_ text: MessageText) {
        self.text = text
    }
}
