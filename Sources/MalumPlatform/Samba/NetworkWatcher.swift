import Foundation
import MalumCore
import Network

/// Says when the network changes, through `NWPathMonitor`.
@MainActor
public final class NetworkWatcher: NetworkWatch {
    /// The monitor while watching.
    private var monitor: NWPathMonitor?

    /// Creates a watcher that watches nothing yet.
    public init() {}

    /// Starts a monitor on the main queue that calls `onChange` for every new path.
    public func watch(_ onChange: @escaping @MainActor () -> Void) {
        stopWatching()
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { _ in MainActor.assumeIsolated { onChange() } }
        monitor.start(queue: .main)
        self.monitor = monitor
    }

    /// Stops the monitor.
    public func stopWatching() {
        monitor?.cancel()
        monitor = nil
    }
}
