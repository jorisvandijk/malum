// MARK: - ReportableError

extension ScreenshotError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .noScreen:
            .couldnt("take a screenshot", "no screen is under the mouse")
        case .captureFailed(let reason):
            .couldnt("take a screenshot", "\(reason)")
        case .unencodable:
            .couldnt("save the screenshot", "it couldn't be made into a PNG")
        }
    }
}
