/// Sends signals to other processes, behind a protocol so tests never signal a real one.
public protocol Signals: Sendable {
    /// Sends `SIGHUP` to process `processID`, which asks the app to reload.
    func hangUp(_ processID: Int32) throws(InstanceError)
}
