/// Why one web app couldn't be made.
enum WebAppError: Error, Equatable, Sendable {
    /// Another app, not one of Malum's web apps, is where the web app would go.
    case inTheWay(path: String)
    /// `sips` couldn't turn the icon into an app icon.
    case icon(reason: String)
    /// A file of the bundle couldn't be read or written.
    case files(FileSystemError)
    /// The bundle couldn't be signed.
    case signing(SigningError)
}
