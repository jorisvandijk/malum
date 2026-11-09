import Foundation

@testable import MalumCore

/// An app whose windows the test sets.
@MainActor
final class FakeWatchedApp: WatchedApp {
    /// Its windows, front to back, or nil when it doesn't answer.
    var current: [FakeAppWindow]? = []
    var isHidden = false
    private(set) var isStopped = false

    func windows() -> [any AppWindow]? {
        current
    }

    func stop() {
        isStopped = true
    }
}
