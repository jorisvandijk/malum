import Synchronization

@testable import MalumCore

/// Records the signals it's asked to send instead of sending them.
final class FakeSignals: Signals {
    /// Processes that can't be signalled.
    let failing: Set<Int32>
    /// Every process sent `SIGHUP`, in order.
    private let hangUps = Mutex<[Int32]>([])

    init(failing: Set<Int32> = []) {
        self.failing = failing
    }

    var sent: [Int32] { hangUps.withLock { $0 } }

    func hangUp(_ processID: Int32) throws(InstanceError) {
        guard !failing.contains(processID) else {
            throw .unsignalable(processID: processID, reason: "no such process")
        }
        hangUps.withLock { $0.append(processID) }
    }
}
