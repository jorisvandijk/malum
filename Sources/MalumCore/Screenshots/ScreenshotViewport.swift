import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// How the kept part of a frozen screen is shown in the overlay: centered on the screen at a zoom,
/// shifted by a pan. Zoom only changes the view; saved files are always real size. Before a crop,
/// at real size, every point of the overlay is the same point of the shot.
public struct ScreenshotViewport: Equatable, Sendable {
    /// How much one zoom step changes the scale.
    private static let step = 1.25
    /// Half, for centering.
    private static let half = 0.5
    /// The smallest scale.
    static let minScale = 0.25
    /// The largest scale.
    static let maxScale = 8.0

    /// The overlay's area, the same as the frozen screen.
    public let screen: CGRect
    /// The part of the shot shown, in the shot's points.
    public private(set) var crop: CGRect
    /// How many overlay points one point of the shot takes.
    public private(set) var scale = 1.0
    /// How far the shown part is moved from the center.
    public private(set) var pan = CGPoint.zero

    /// Creates the viewport of a shot of `screen`, showing all of it at real size.
    public init(screen: CGRect) {
        self.screen = screen
        crop = screen
    }

    /// Where the kept part is drawn in the overlay.
    public var shown: CGRect {
        let size = CGSize(width: crop.width * scale, height: crop.height * scale)
        return CGRect(
            x: screen.midX - size.width * Self.half + pan.x, y: screen.midY - size.height * Self.half + pan.y,
            width: size.width, height: size.height)
    }

    /// Shows `crop`, centered at real size. Called whenever the kept part changes, undo included.
    public mutating func show(_ crop: CGRect) {
        self.crop = crop
        reset()
    }

    /// The point of the shot under `point` of the overlay.
    public func shotPoint(at point: CGPoint) -> CGPoint {
        let shown = shown
        return CGPoint(x: crop.minX + (point.x - shown.minX) / scale, y: crop.minY + (point.y - shown.minY) / scale)
    }

    /// The point of the overlay where `point` of the shot is drawn.
    public func overlayPoint(at point: CGPoint) -> CGPoint {
        let shown = shown
        return CGPoint(x: shown.minX + (point.x - crop.minX) * scale, y: shown.minY + (point.y - crop.minY) * scale)
    }

    /// Zooms by `factor`, such as a pinch's, keeping the shot's point under `anchor` where it is.
    /// The scale stays between `minScale` and `maxScale`.
    public mutating func zoom(by factor: Double, at anchor: CGPoint) {
        let held = shotPoint(at: anchor)
        scale = min(max(scale * factor, Self.minScale), Self.maxScale)
        let moved = overlayPoint(at: held)
        pan = CGPoint(x: pan.x + anchor.x - moved.x, y: pan.y + anchor.y - moved.y)
    }

    /// Zooms one step in, keeping the middle of the overlay where it is.
    public mutating func zoomIn() {
        zoom(by: Self.step, at: CGPoint(x: screen.midX, y: screen.midY))
    }

    /// Zooms one step out, keeping the middle of the overlay where it is.
    public mutating func zoomOut() {
        zoom(by: 1 / Self.step, at: CGPoint(x: screen.midX, y: screen.midY))
    }

    /// Moves the shown part by `offset`, such as a scroll's.
    public mutating func move(by offset: CGPoint) {
        pan = CGPoint(x: pan.x + offset.x, y: pan.y + offset.y)
    }

    /// Shows the kept part centered at real size again.
    public mutating func reset() {
        scale = 1
        pan = .zero
    }
}
