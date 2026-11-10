@testable import MalumCore

/// Keeps the desktop pictures in memory instead of asking macOS.
@MainActor
final class FakeDesktop: Desktop {
    /// Why showing a picture fails, or nil when it works.
    private let failure: FileSystemError?
    /// The picture each screen shows.
    private(set) var shown: [String?]

    init(shown: [String?] = [nil], failure: FileSystemError? = nil) {
        self.shown = shown
        self.failure = failure
    }

    func pictures() -> [String?] { shown }

    func show(_ path: String) throws {
        if let failure { throw failure }
        shown = shown.map { _ in path }
    }
}
