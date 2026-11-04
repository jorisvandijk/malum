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

// MARK: - ReportableError

extension InstanceError: ReportableError {
    /// The problem as the user sees it.
    public var text: MessageText {
        switch self {
        case .notRunning:
            "couldn't reach \(Project.name): it isn't running"
        case .noProcessID(let path):
            "couldn't reach \(Project.name): no process ID in \(private: path)"
        case .unsignalable(let processID, let reason):
            "couldn't signal \(Project.name) (process \(processID)): \(reason)"
        case .state(let error):
            error.text
        }
    }
}
