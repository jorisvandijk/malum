import Foundation

/// Sends real signals, through `kill`.
public struct LocalSignals: Signals {
    /// Creates access to real signals.
    public init() {}

    /// Sends `SIGHUP` to process `processID`.
    public func hangUp(_ processID: Int32) throws(InstanceError) {
        guard kill(processID, SIGHUP) == 0 else {
            throw .unsignalable(processID: processID, reason: String(cString: strerror(errno)))
        }
    }
}
