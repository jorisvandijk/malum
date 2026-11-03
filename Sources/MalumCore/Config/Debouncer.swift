/// Runs an action once things have been quiet for a while, such as a file that's saved in several steps.
@MainActor
public final class Debouncer {
    /// How long to wait after the last call.
    private let delay: Duration
    /// The action waiting to run.
    private var pending: Task<Void, Never>?

    /// Creates a debouncer that waits `delay` after the last call.
    public init(delay: Duration) {
        self.delay = delay
    }

    /// Runs `action` after the delay, unless another call comes first and replaces it.
    public func schedule(_ action: @escaping @MainActor () -> Void) {
        pending?.cancel()
        pending = Task { [delay] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return  // Cancelled, because a newer call replaced this one.
            }
            action()
        }
    }

    /// Drops the action waiting to run, if any.
    public func cancel() {
        pending?.cancel()
        pending = nil
    }
}
