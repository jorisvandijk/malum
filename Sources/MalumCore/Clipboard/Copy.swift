import Foundation

/// What was copied, as the pasteboard watcher reads it.
public enum Copy: Equatable, Sendable {
    /// Text, with the rich text copied along with it, so a paste into Notes keeps its formatting.
    case text(String, rtf: Data?)
    /// An image, as PNG.
    case image(png: Data)
    /// The paths of copied files, never the files themselves.
    case files([String])
}
