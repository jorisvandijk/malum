import Foundation

@testable import MalumCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// Gives back the edits it's told to, as if the user saved them, or nil for cancel.
@MainActor
final class FakeScreenshotOverlay: ScreenshotOverlay {
    /// What the user does to the shot: nil cancels.
    var result: ((ScreenshotEdits) -> ScreenshotEdits)?
    /// The quick colors each overlay was opened with.
    private(set) var opened: [[ScreenshotColor]] = []

    func edit(_ frozen: any FrozenScreen, quickColors: [ScreenshotColor]) async -> ScreenshotEdits? {
        opened.append(quickColors)
        return result.map { $0(ScreenshotEdits(screen: frozen.screen)) }
    }
}
