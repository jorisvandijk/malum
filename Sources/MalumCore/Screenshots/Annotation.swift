import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// One thing drawn on a shot, in the frozen screen's points so it stays put when the shot is cropped.
public struct Annotation: Equatable, Sendable {
    /// What is drawn.
    public enum Shape: Equatable, Sendable {
        /// A straight line from one point to another.
        case line(from: CGPoint, to: CGPoint)
        /// A line with an arrowhead at `to`.
        case arrow(from: CGPoint, to: CGPoint)
        /// A rectangle's outline.
        case rectangle(CGRect)
        /// Text whose first line starts at `at`.
        case text(String, at: CGPoint)
    }

    /// What is drawn.
    public let shape: Shape
    /// The color it's drawn in.
    public let color: ScreenshotColor
    /// The line width or text size.
    public let size: AnnotationSize

    /// Creates an annotation.
    public init(_ shape: Shape, color: ScreenshotColor, size: AnnotationSize) {
        self.shape = shape
        self.color = color
        self.size = size
    }

    /// The shape `tool` draws when dragged from `start` to `end`, or nil when the tool doesn't draw
    /// by dragging (select and text) or the drag didn't move.
    public static func dragged(_ tool: ScreenshotTool, from start: CGPoint, to end: CGPoint) -> Shape? {
        guard start != end else { return nil }
        switch tool {
        case .line: return .line(from: start, to: end)
        case .arrow: return .arrow(from: start, to: end)
        case .rectangle: return .rectangle(CGRect(corner: start, corner: end))
        case .select, .text: return nil
        }
    }
}

extension CGRect {
    /// The rectangle with `corner` and `other` at opposite corners, whichever way they lie.
    init(corner: CGPoint, corner other: CGPoint) {
        self.init(
            x: min(corner.x, other.x), y: min(corner.y, other.y),
            width: abs(other.x - corner.x), height: abs(other.y - corner.y))
    }
}
