@testable import MalumCore

/// Running apps as the test sets them, and events the test sends.
@MainActor
final class FakeAppWatcher: AppWatcher {
    /// The apps that run.
    var apps: [RunningApp] = []
    /// Where events go while it runs.
    private var onEvent: (@MainActor @Sendable (AppEvent) -> Void)?

    /// Whether it runs.
    var isStarted: Bool { onEvent != nil }

    func runningApps() -> [RunningApp] {
        apps
    }

    func start(_ onEvent: @escaping @MainActor @Sendable (AppEvent) -> Void) {
        self.onEvent = onEvent
    }

    func stop() {
        onEvent = nil
    }

    /// Sends `event` as macOS would.
    func send(_ event: AppEvent) {
        onEvent?(event)
    }
}
