import Synchronization

@testable import MalumCore

/// Locks held in memory. Paths in `heldElsewhere` act as if another process holds them.
final class FakeFileLocks: FileLocks {
    /// Locks another process holds.
    let heldElsewhere: Set<String>
    /// Lock files that can't be opened.
    let failing: Set<String>
    /// Locks this process holds for life.
    private let heldHere = Mutex<Set<String>>([])
    /// Every path `withLock` ran under, in order.
    private let lockedRuns = Mutex<[String]>([])

    init(heldElsewhere: Set<String> = [], failing: Set<String> = []) {
        self.heldElsewhere = heldElsewhere
        self.failing = failing
    }

    var held: Set<String> { heldHere.withLock { $0 } }
    var runs: [String] { lockedRuns.withLock { $0 } }

    func holdForLife(_ path: String) throws(StateError) -> Bool {
        try check(path)
        guard !heldElsewhere.contains(path) else { return false }
        heldHere.withLock { _ = $0.insert(path) }
        return true
    }

    func isHeld(_ path: String) throws(StateError) -> Bool {
        try check(path)
        return heldElsewhere.contains(path)
    }

    func withLock<T>(_ path: String, _ body: () throws(StateError) -> T) throws(StateError) -> T {
        try check(path)
        lockedRuns.withLock { $0.append(path) }
        return try body()
    }

    private func check(_ path: String) throws(StateError) {
        guard !failing.contains(path) else { throw .unlockable(path: path, reason: "permission denied") }
    }
}
