/// The words for why the window manager couldn't do its work.
extension WindowManagerError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .notInstalled(let bundleID):
            .couldnt("open \(bundleID)", "no app with this bundle ID is installed")
        case .openFailed(let bundleID, let reason):
            .couldnt("open \(bundleID)", MessageText(reason))
        }
    }
}
