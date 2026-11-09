/// Runs the window manager's later work, such as a look at a window that wasn't ready yet. Tests use
/// a fake that runs it when told, so nothing waits on a clock.
@MainActor
protocol WindowScheduler: AnyObject {
    /// The time now.
    var now: ContinuousClock.Instant { get }
    /// Runs `action` after `delay`.
    func after(_ delay: Duration, _ action: @escaping @MainActor () -> Void)
}

/// The real scheduler, on the main actor's clock.
@MainActor
final class TaskScheduler: WindowScheduler {
    /// The clock it reads.
    private let clock = ContinuousClock()

    /// The time now.
    var now: ContinuousClock.Instant { clock.now }

    /// Runs `action` after `delay`, unless the wait is cancelled.
    func after(_ delay: Duration, _ action: @escaping @MainActor () -> Void) {
        Task {
            do {
                try await Task.sleep(for: delay)
            } catch {
                return  // Cancelled, so the action no longer applies.
            }
            action()
        }
    }
}
