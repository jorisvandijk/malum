import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// A screen frozen the moment the screenshot key was pressed, which the overlay shows and the
/// saved files are cut from.
@MainActor
public protocol FrozenScreen: AnyObject {
    /// The screen in points, with its top-left corner at zero and y growing down, the space crops
    /// and annotations are in.
    var screen: CGRect { get }

    /// The part `crop` of the shot as PNG, with `annotations` drawn on it at real size.
    func png(crop: CGRect, annotations: [Annotation]) throws(ScreenshotError) -> Data

    #if canImport(CoreGraphics)
        /// The frozen screen's pixels, for the overlay to show.
        var image: CGImage { get }
    #endif
}

/// Freezes the screen for a screenshot.
@MainActor
public protocol ScreenCapture {
    /// Freezes the screen the mouse is on.
    func freeze() async throws(ScreenshotError) -> any FrozenScreen
}
