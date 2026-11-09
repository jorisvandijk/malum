import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// The filled triangle at the end of an arrow.
public enum ArrowHead {
    /// How long the head is, in line widths.
    private static let lengthPerWidth = 4.0
    /// The shortest head, so a thin arrow still shows one.
    private static let minLength = 12.0
    /// How far each side of the head reaches from the line, against the head's length.
    private static let sidePerLength = 0.4

    /// The head's three corners, the tip at `end`, for an arrow from `start` drawn `lineWidth` wide.
    /// Empty when the arrow has no length.
    public static func corners(from start: CGPoint, to end: CGPoint, lineWidth: Double) -> [CGPoint] {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0 else { return [] }
        let headLength = min(max(lineWidth * lengthPerWidth, minLength), length)
        let along = CGPoint(x: dx / length, y: dy / length)
        let base = CGPoint(x: end.x - along.x * headLength, y: end.y - along.y * headLength)
        let side = headLength * sidePerLength
        return [
            end,
            CGPoint(x: base.x - along.y * side, y: base.y + along.x * side),
            CGPoint(x: base.x + along.y * side, y: base.y - along.x * side),
        ]
    }
}
