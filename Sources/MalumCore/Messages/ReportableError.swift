/// An error the user sees, with the private parts of its text marked for the log.
public protocol ReportableError: Error, CustomStringConvertible {
    /// The problem as the user sees it.
    var text: MessageText { get }
}

extension ReportableError {
    /// The problem as the user sees it, private parts included.
    public var description: String { text.description }
}

extension MessageText {
    /// The reason `error` gives, for a message: its own text when it's reportable.
    init(error: any Error) {
        self = (error as? any ReportableError)?.text ?? MessageText(String(describing: error))
    }
}
