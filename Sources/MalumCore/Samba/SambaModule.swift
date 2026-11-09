import Foundation
import Observation

/// Keeps the shares in `samba.toml` mounted under `/Volumes` while their servers answer: at start,
/// on every network change and every few minutes. A share whose server stops answering is unmounted,
/// so nothing hangs on it.
@Observable
@MainActor
final class SambaModule: Module {
    /// How long between two looks, on top of network changes: five minutes.
    static let interval: TimeInterval = 300
    /// Where macOS mounts shares.
    static let volumes = "/Volumes"

    /// The module's id.
    let id = SambaConfig.module
    /// Mounting needs no permission Malum can check; macOS asks for network volumes itself.
    let permissions: Set<Permission> = []
    /// Its settings.
    var schema: ConfigSchema { SambaConfig.schema }
    /// Where the module is now.
    private(set) var status = ModuleStatus.off

    /// What it works through.
    @ObservationIgnored private let system: SambaSystem
    /// The module's own log.
    @ObservationIgnored private let log: Log
    /// The time now, which tests set.
    @ObservationIgnored private let now: () -> Date
    /// The settings last given.
    @ObservationIgnored private var config = SambaConfig(servers: [])
    /// The shares taken out of the settings since the last look, to unmount.
    @ObservationIgnored private var dropped: [(server: SambaServer, share: String)] = []
    /// Each share's state from the last look, by `server/share`.
    @ObservationIgnored private var states: [String: ShareState] = [:]
    /// When the last look ended.
    @ObservationIgnored private var lastLook: Date?
    /// Whether the module runs.
    @ObservationIgnored private var isRunning = false
    /// Whether a look is under way.
    @ObservationIgnored private var isLooking = false
    /// Whether something asked for a look while one was under way.
    @ObservationIgnored private var looksAgain = false
    /// The look started last, which tests wait for.
    @ObservationIgnored private(set) var work: Task<Void, Never>?

    /// Creates the module, off.
    init(system: SambaSystem, log: Log, now: @escaping () -> Date = Date.init) {
        self.system = system
        self.log = log.module(SambaConfig.module)
        self.now = now
    }

    /// Nothing to undo: mounted shares stay as macOS keeps them.
    func cleanUp() async throws {}

    /// Takes new servers, unmounting the shares that are gone, and looks again.
    func apply(_ settings: ModuleSettings) {
        let old = config.servers
        config = SambaConfig.read(settings.table) { _, _ in }
        dropped += old.flatMap { server in
            server.shares.filter { !isListed($0, on: server) }.map { (server: server, share: $0) }
        }
        lookSoon()
    }

    /// Mounts the shares and starts watching the network.
    func start() async throws {
        status = .starting
        isRunning = true
        system.network.watch { [weak self] in self?.lookSoon() }
        await look()
    }

    /// Stops watching. Mounted shares stay mounted.
    func stop() async {
        system.network.stopWatching()
        isRunning = false
        await work?.value
        states = [:]
        status = .off
    }

    /// Looks again once the interval has passed since the last look.
    func check() {
        guard isRunning, !isLooking, let lastLook, now().timeIntervalSince(lastLook) >= Self.interval else { return }
        lookSoon()
    }

    /// Starts a look, or asks the one under way to look once more.
    private func lookSoon() {
        guard isRunning else { return }
        guard !isLooking else {
            looksAgain = true
            return
        }
        work = Task { await look() }
    }

    /// Unmounts the dropped shares, then mounts or unmounts each listed share, until nothing asked for
    /// another look meanwhile.
    private func look() async {
        isLooking = true
        repeat {
            looksAgain = false
            await unmountDropped()
            await mountListed()
        } while looksAgain && isRunning
        lastLook = now()
        isLooking = false
        let problem = config.servers.lazy.flatMap { server in
            server.shares.lazy.compactMap { share in self.problem(share, on: server) }
        }.first
        status = problem.map { .degraded(reason: $0) } ?? .running
    }

    /// What's wrong with `share` on `server`, or nil when nothing is.
    private func problem(_ share: String, on server: SambaServer) -> String? {
        guard let state = states[Self.key(share, on: server)], state.isProblem else { return nil }
        return state.message(share, on: server).text.description
    }

    /// Unmounts the shares taken out of the settings that are still mounted.
    private func unmountDropped() async {
        let mounts = system.shares.mounts()
        let gone = dropped
        dropped = []
        for (server, share) in gone {
            states[Self.key(share, on: server)] = nil
            guard let mount = mounts.first(where: { $0.isShare(share, on: server) }) else { continue }
            let result = await system.runner.run(Umount.force(mount.path))
            log.report(result.succeeded ? .unmountedDropped(mount.path) : .couldntUnmount(mount.path, result.reason))
        }
    }

    /// Brings each listed share to where it should be, logging what changed.
    private func mountListed() async {
        let mounts = system.shares.mounts()
        for server in config.servers {
            let reachable = await system.shares.isReachable(server.host)
            for share in server.shares {
                let mounted = mounts.first { $0.isShare(share, on: server) }
                let state = await state(of: share, on: server, mounted: mounted, reachable: reachable)
                let key = Self.key(share, on: server)
                if states[key] != state { log.report(state.message(share, on: server)) }
                states[key] = state
            }
        }
    }

    /// Mounts or unmounts `share` on `server`, now `mounted` or not, as `reachable` says.
    private func state(of share: String, on server: SambaServer, mounted: SambaMount?, reachable: Bool) async
        -> ShareState
    {
        if let mounted {
            guard !reachable else { return .mounted(path: mounted.path) }
            let result = await system.runner.run(Umount.force(mounted.path))
            guard result.succeeded else { return .stuck(path: mounted.path, reason: result.reason) }
            return .unmounted(path: mounted.path)
        }
        guard reachable else { return .unreachable }
        let volume = "\(Self.volumes)/\(share)"
        guard system.files.item(at: volume) == nil else { return .taken(path: volume) }
        return await mount(share, from: server, at: volume)
    }

    /// Mounts `share` from `server` at `volume` with the password in the keychain.
    private func mount(_ share: String, from server: SambaServer, at volume: String) async -> ShareState {
        let password: String?
        do {
            password = try system.passwords(server).token()
        } catch {
            return .unreadablePassword(error)
        }
        guard let password else { return .noPassword }
        do {
            try await system.shares.mount(share, from: server, password: password)
        } catch {
            return .failed(error)
        }
        return .mounted(path: volume)
    }

    /// Whether `share` on `server`'s host is still in the settings.
    private func isListed(_ share: String, on server: SambaServer) -> Bool {
        config.servers.contains { listed in
            listed.host.lowercased() == server.host.lowercased()
                && listed.shares.contains { $0.lowercased() == share.lowercased() }
        }
    }

    /// The key of `share` on `server` in `states`.
    private static func key(_ share: String, on server: SambaServer) -> String {
        "\(server.name)/\(share)"
    }
}
