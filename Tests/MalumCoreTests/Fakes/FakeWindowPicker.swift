@testable import MalumCore

/// A picker that answers at once, clicked or cancelled as the test sets it.
@MainActor
final class FakeWindowPicker: WindowPicker {
    /// Whether the user clicks.
    var clicks = true
    /// How often a click was waited for.
    private(set) var picks = 0

    func pick() async -> Bool {
        picks += 1
        return clicks
    }
}
