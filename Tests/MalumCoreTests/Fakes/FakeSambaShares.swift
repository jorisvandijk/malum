import Synchronization

@testable import MalumCore

/// Samba shares kept in memory: a share mounts at `/Volumes/<share>` when its host answers, unless
/// `failure` is set.
final class FakeSambaShares: SambaShares {
    /// The hosts that answer.
    let reachable = Mutex<Set<String>>([])
    /// What mounting throws, or nil to work.
    let failure = Mutex<SambaMountError?>(nil)
    /// The shares mounted now.
    let mounted = Mutex<[SambaMount]>([])
    /// Each mount asked for, as `user@host/share password`.
    let asked = Mutex<[String]>([])

    func mounts() -> [SambaMount] { mounted.withLock { $0 } }

    func isReachable(_ host: String) async -> Bool { reachable.withLock { $0.contains(host) } }

    func mount(_ share: String, from server: SambaServer, password: String) async throws(SambaMountError) {
        asked.withLock { $0.append("\(server.account)/\(share) \(password)") }
        if let failure = failure.withLock({ $0 }) { throw failure }
        add(share, on: server.host)
    }

    /// Marks `share` on `host` mounted.
    func add(_ share: String, on host: String) {
        let mount = SambaMount(source: "//me@\(host)/\(share)", path: "/Volumes/\(share)")
        mounted.withLock { list in mount.map { list.append($0) } }
    }

    /// Takes the mount at `path` away, as `diskutil` does.
    func remove(_ path: String) {
        mounted.withLock { $0.removeAll { $0.path == path } }
    }
}

/// A network that changes only when a test says so.
@MainActor
final class FakeNetworkWatch: NetworkWatch {
    /// What's called on a change, while watched.
    private var onChange: (@MainActor () -> Void)?

    var isWatching: Bool { onChange != nil }

    func watch(_ onChange: @escaping @MainActor () -> Void) { self.onChange = onChange }

    func stopWatching() { onChange = nil }

    /// Changes the network.
    func change() { onChange?() }
}
