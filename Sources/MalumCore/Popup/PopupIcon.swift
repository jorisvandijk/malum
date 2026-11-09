/// The picture at the start of a popup row.
public enum PopupIcon: Hashable, Sendable {
    /// No picture.
    case none
    /// The Finder icon of the file, folder or app at this path.
    case file(String)
    /// A small copy of the image file at this path.
    case image(String)
}
