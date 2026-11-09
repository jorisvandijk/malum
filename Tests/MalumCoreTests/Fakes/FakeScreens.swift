@testable import MalumCore

/// A screen the test sets.
@MainActor
final class FakeScreens: Screens {
    /// The screen with the menu bar, or nil for none.
    var screen: ScreenRects?

    func main() -> ScreenRects? {
        screen
    }
}
