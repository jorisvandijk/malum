// MARK: - ReportableError

extension ClipHistoryError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .unreadable(let path):
            .couldnt("read the clipboard history at \(private: path)", "it isn't a history \(Project.name) wrote")
        case .file(let error):
            error.text
        }
    }
}
