import Foundation

/// The part of a picture to keep, measured in pixels from its bottom-left corner, the way macOS
/// keeps the crop of the Apple Account's picture.
public struct PictureCrop: Equatable, Sendable {
    /// How many numbers the text form holds: x, y, width and height.
    private static let numberCount = 4

    /// Pixels from the left edge.
    public let left: Double
    /// Pixels from the bottom edge.
    public let bottom: Double
    /// The width in pixels.
    public let width: Double
    /// The height in pixels.
    public let height: Double

    /// Creates the crop.
    public init(left: Double, bottom: Double, width: Double, height: Double) {
        self.left = left
        self.bottom = bottom
        self.width = width
        self.height = height
    }

    /// Reads the crop as macOS writes a rectangle, such as `{{117, 190}, {827, 827}}`, or gives
    /// nil when `text` isn't one.
    init?(_ text: String) {
        let numbers = text.split { !"0123456789.-".contains($0) }.compactMap { Double($0) }
        let middle = numbers.dropFirst().dropLast()
        guard
            numbers.count == Self.numberCount, let left = numbers.first, let bottom = middle.first,
            let width = middle.last, let height = numbers.last
        else { return nil }
        self.init(left: left, bottom: bottom, width: width, height: height)
    }
}
