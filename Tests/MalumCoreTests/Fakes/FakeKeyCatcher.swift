@testable import MalumCore

/// Catches no keys, but writes down every session it's given, and refuses when told to.
@MainActor
final class FakeKeyCatcher: KeyCatcher {
    /// Whether `start` says macOS refused the tap.
    var refuses = false
    /// How many times a session was started.
    private(set) var starts = 0
    /// Whether a session runs now, which a test sets to false to play macOS switching the tap off.
    var isRunning = false

    func start(_ session: TapSession) -> Bool {
        guard !refuses else { return false }
        starts += 1
        isRunning = true
        return true
    }

    func stop() {
        isRunning = false
    }
}
