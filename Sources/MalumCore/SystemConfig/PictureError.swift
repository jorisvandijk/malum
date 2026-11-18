/// Why a square picture couldn't be made.
public enum PictureError: Error, Equatable, Sendable {
    /// The file at the path isn't a picture macOS can read.
    case unreadable(path: String)
    /// The square couldn't be made from the picture at the path.
    case notMade(path: String)
}
