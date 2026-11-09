import Foundation

@testable import MalumCore

/// A clock the test moves, and later work it runs when told.
@MainActor
final class FakeScheduler: WindowScheduler {
    var now = ContinuousClock().now
    /// The work waiting, in the order it was asked for.
    private(set) var pending: [@MainActor () -> Void] = []

    func after(_ delay: Duration, _ action: @escaping @MainActor () -> Void) {
        pending.append(action)
    }

    /// Runs what's waiting now, but not what that work asks for in turn.
    func runPending() {
        let due = pending
        pending = []
        for action in due {
            action()
        }
    }
}
