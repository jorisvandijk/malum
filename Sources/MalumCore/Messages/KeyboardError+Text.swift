/// The words for why the keyboard module couldn't do its work.
extension KeyboardError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .tapRefused:
            .couldnt("catch keys", "macOS refused the event tap")
        }
    }
}
