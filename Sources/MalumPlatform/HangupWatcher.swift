import Dispatch
import Foundation

/// Calls back on the main actor each time the process gets `SIGHUP`, which `malum reload` sends.
@MainActor
public final class HangupWatcher {
    /// Hands the signal over to the main queue.
    private let source: DispatchSourceSignal

    /// Starts watching. `onHangup` runs on the main actor for each signal.
    public init(onHangup: @escaping @MainActor @Sendable () -> Void) {
        // Without this, SIGHUP would end the process before the source sees it.
        signal(SIGHUP, SIG_IGN)
        source = DispatchSource.makeSignalSource(signal: SIGHUP, queue: .main)
        source.setEventHandler { MainActor.assumeIsolated { onHangup() } }
        source.resume()
    }
}
