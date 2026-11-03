import Foundation

/// Makes sure only one Malum app runs at a time, and lets the command find it.
///
/// The app holds the lock on `app.lock` in the state folder for as long as it runs, and writes its
/// process ID to `app.pid`. A process ID is only trusted while the lock is held, so one left behind
/// by a crash is never used.
public struct AppInstance: Sendable {
    /// The file the running app keeps locked.
    private static let lockName = "app.lock"
    /// The file that holds the running app's process ID.
    private static let processIDName = "app.pid"

    /// The state folder.
    private let state: StateFolder
    /// The locks.
    private let locks: any FileLocks

    /// Creates the app's place in `state`.
    public init(state: StateFolder, locks: any FileLocks) {
        self.state = state
        self.locks = locks
    }

    /// Claims the app's place for process `processID`. Returns false when another app already runs.
    public func claim(processID: Int32) throws(InstanceError) -> Bool {
        do {
            try state.prepare()
            guard try locks.holdForLife(state.path(of: Self.lockName)) else { return false }
            try state.write("\(processID)\n", to: Self.processIDName)
            return true
        } catch {
            throw .state(error)
        }
    }

    /// The running app's process ID. Throws `notRunning` when no app runs.
    public func runningProcessID() throws(InstanceError) -> Int32 {
        guard try isRunning() else { throw .notRunning }
        let text: String?
        do {
            text = try state.read(Self.processIDName)
        } catch {
            throw .state(error)
        }
        guard let text, let processID = Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw .noProcessID(path: state.path(of: Self.processIDName))
        }
        return processID
    }

    /// Whether an app holds the lock.
    private func isRunning() throws(InstanceError) -> Bool {
        do {
            try state.prepare()
            return try locks.isHeld(state.path(of: Self.lockName))
        } catch {
            throw .state(error)
        }
    }
}
