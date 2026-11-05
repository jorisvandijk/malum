/// Why `malum init` or the link at first start failed.
public enum SetupError: Error, Equatable, Sendable {
    /// The dots folder given to `malum init` doesn't exist.
    case dotsNotFound(path: String)
    /// Something other than a link sits where the command link goes.
    case occupied(path: String)
    /// Malum runs from somewhere other than Malum.app, such as a build folder, so there's nothing to link to.
    case notInApp(path: String)
    /// Reading or writing a file failed.
    case file(FileSystemError)
}

// MARK: - ReportableError

extension SetupError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .dotsNotFound(let path):
            "couldn't use \(private: path) as dots: folder not found"
        case .occupied(let path):
            "couldn't link \(private: path): something that isn't a link is there, move it away and run init again"
        case .notInApp(let path):
            "couldn't link \(private: path): \(Project.name) isn't running from \(Project.name).app"
        case .file(let error):
            error.text
        }
    }
}
