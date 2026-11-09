import Foundation

/// Sends real signals, through `kill`.
public struct LocalSignals: Signals {
    /// Creates access to real signals.
    public init() {}

    /// Sends `SIGHUP` to process `processID`.
    public func hangUp(_ processID: Int32) throws(InstanceError) {
        try send(SIGHUP, to: processID)
    }

    /// Sends `SIGUSR1` to process `processID`.
    public func askForActions(_ processID: Int32) throws(InstanceError) {
        try send(SIGUSR1, to: processID)
    }

    /// Sends `signal` to process `processID`.
    private func send(_ signal: Int32, to processID: Int32) throws(InstanceError) {
        guard kill(processID, signal) == 0 else {
            throw .unsignalable(processID: processID, reason: String(cString: strerror(errno)))
        }
    }
}
