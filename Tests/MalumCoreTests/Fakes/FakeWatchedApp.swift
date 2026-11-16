import Foundation

@testable import MalumCore

/// An app whose windows the test sets.
@MainActor
final class FakeWatchedApp: WatchedApp {
    /// Its windows, front to back, or nil when it doesn't answer.
    var current: [FakeAppWindow]? = []
    /// The window with the focus.
    var focused: FakeAppWindow?
    var isHidden = false
    private(set) var isStopped = false

    func windows() -> [any AppWindow]? {
        current
    }

    func focusedWindow() -> (any AppWindow)? {
        focused
    }

    func stop() {
        isStopped = true
    }
}
