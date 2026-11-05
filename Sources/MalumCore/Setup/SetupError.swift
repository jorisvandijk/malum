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
