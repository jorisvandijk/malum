@testable import MalumCore

/// A panel that keeps what it was shown, and clicks Copy when the test asks.
@MainActor
final class FakeInspectorPanel: InspectorPanel {
    /// The lines last shown, or nil when nothing was.
    private(set) var shown: [InspectorLine]?
    /// What Copy does.
    private var onCopy: @MainActor () -> Void = {}

    func show(_ lines: [InspectorLine], onCopy: @escaping @MainActor () -> Void) {
        shown = lines
        self.onCopy = onCopy
    }

    /// Clicks Copy.
    func clickCopy() {
        onCopy()
    }
}
