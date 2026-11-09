import Foundation

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// A window that only exists in the test. It takes any frame up to `maxSize`.
@MainActor
final class FakeAppWindow: AppWindow {
    var facts = WindowFacts(role: "AXWindow", subrole: "AXStandardWindow", title: "Main")
    var frame: CGRect? = CGRect(x: 10, y: 10, width: 300, height: 200)
    var isMinimized = false
    /// The biggest size it takes.
    var maxSize = CGSize(width: 10_000, height: 10_000)
    /// How many times it was given a frame or an origin.
    private(set) var moves = 0

    func setFrame(_ frame: CGRect) {
        moves += 1
        let size = CGSize(width: min(frame.width, maxSize.width), height: min(frame.height, maxSize.height))
        self.frame = CGRect(origin: frame.origin, size: size)
    }

    func setOrigin(_ origin: CGPoint) {
        moves += 1
        frame?.origin = origin
    }

    func isSame(as other: any AppWindow) -> Bool {
        other === self
    }
}
