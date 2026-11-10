@testable import MalumCore

/// Keeps the screen's size in memory instead of asking macOS.
@MainActor
final class FakeDisplay: Display {
    /// Why showing a size fails, or nil when it works.
    private let failure: DisplayError?
    /// The size the screen shows, nil when it's off.
    private(set) var shown: DisplayResolution?

    init(shown: DisplayResolution? = DisplayResolution(width: 1470, height: 956), failure: DisplayError? = nil) {
        self.shown = shown
        self.failure = failure
    }

    func resolution() -> DisplayResolution? { shown }

    func show(_ resolution: DisplayResolution) throws {
        if let failure { throw failure }
        shown = resolution
    }
}
