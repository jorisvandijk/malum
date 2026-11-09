import Dispatch
import Foundation

/// Calls back on the main actor each time the process gets a signal, such as `SIGHUP` from
/// `malum reload` or `SIGTERM` from launchd.
@MainActor
public final class SignalWatcher {
    /// Hands the signal over to the main queue.
    private let source: DispatchSourceSignal

    /// Starts watching for `signal`. `onSignal` runs on the main actor each time it comes.
    public init(_ signal: Int32, onSignal: @escaping @MainActor @Sendable () -> Void) {
        // Without this, the signal would end the process before the source sees it.
        Darwin.signal(signal, SIG_IGN)
        source = DispatchSource.makeSignalSource(signal: signal, queue: .main)
        source.setEventHandler { MainActor.assumeIsolated { onSignal() } }
        source.resume()
    }
}
