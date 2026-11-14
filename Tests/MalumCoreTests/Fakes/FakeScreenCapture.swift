import Foundation

@testable import MalumCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// Hands out a frozen screen, or fails.
@MainActor
final class FakeScreenCapture: ScreenCapture {
    let frozen = FakeFrozenScreen()
    /// The error freezing gives, if any.
    var error: ScreenshotError?
    /// How often the screen was frozen.
    private(set) var freezes = 0

    func freeze() async throws(ScreenshotError) -> any FrozenScreen {
        freezes += 1
        if let error { throw error }
        return frozen
    }
}
