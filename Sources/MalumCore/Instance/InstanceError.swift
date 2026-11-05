/// Why finding or signalling the running app failed.
public enum InstanceError: Error, Equatable, Sendable {
    /// No app is running.
    case notRunning
    /// The app is running, but the file that should hold its process ID doesn't.
    case noProcessID(path: String)
    /// Sending the signal to the process failed.
    case unsignalable(processID: Int32, reason: String)
    /// Using the state folder failed.
    case state(StateError)
}
