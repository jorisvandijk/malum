import Foundation

/// One entry of the clipboard history.
public struct ClipEntry: Codable, Equatable, Sendable {
    /// What kind of copy it is.
    public enum Kind: String, Codable, Sendable {
        /// Text, maybe with rich text.
        case text
        /// An image, kept as a PNG file next to the history.
        case image
        /// Paths of copied files.
        case files
    }

    /// Tells the entry apart from the others.
    public let id: String
    /// What kind of copy it is.
    public let kind: Kind
    /// When it was copied, or last picked.
    public var date: Date
    /// The text of a text entry.
    public var text: String?
    /// The rich text copied with a text entry.
    public var rtf: Data?
    /// The paths of a files entry.
    public var paths: [String]?
    /// A fingerprint of an image entry's bytes, to notice the same image copied again.
    public var imageHash: String?

    /// Two entries with the same key are the same copy.
    var key: String {
        switch kind {
        case .text:
            "t:\(text ?? "")"
        case .files:
            "f:\((paths ?? []).joined(separator: "\n"))"
        case .image:
            "i:\(imageHash ?? id)"
        }
    }

    /// The name of an image entry's PNG file in the history folder.
    var imageName: String { "\(id).png" }
}
