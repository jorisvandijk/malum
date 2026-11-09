import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// One window an `AppTracker` knows, with what it decided about it.
@MainActor
final class TrackedWindow {
    /// The window.
    let window: any AppWindow
    /// What the tracker does with it.
    var kind = WindowKind.notReady
    /// Where the tracker last put it, or nil when it hasn't yet.
    var slot: CGRect?
    /// The frame the window ended up with after it was put in its slot. Any other frame is snapped back.
    var settled: CGRect?
    /// When it was snapped back lately, to notice an app that fights every move.
    var snaps: [ContinuousClock.Instant] = []

    /// Starts knowing `window`, not ready yet.
    init(_ window: any AppWindow) {
        self.window = window
    }

    /// Forgets where it was put, so it's put in its slot again.
    func forgetPlace() {
        slot = nil
        settled = nil
        snaps = []
    }
}
