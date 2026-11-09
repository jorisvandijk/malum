import Foundation
import Synchronization
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct SambaModuleTests {
    private let shares = FakeSambaShares()
    private let network = FakeNetworkWatch()
    private let files = FakeFileSystem()
    private let writer = RecordingLogWriter()
    private let password = FakeTokenStore("secret")
    private let clock = TestClock()
    private let nas: ConfigValue = .table([
        "name": .string("nas"), "host": .string("nas.local"), "user": .string("joris"),
        "shares": .array([.string("media"), .string("backup")]),
    ])

    /// A runner whose `umount` takes the mount away.
    private var runner: FakeRunner {
        FakeRunner { [shares] command in
            command.arguments.last.map(shares.remove)
            return CommandResult(status: 0)
        }
    }

    private func started(_ servers: [ConfigValue], runner: FakeRunner? = nil) async throws -> SambaModule {
        let system = SambaSystem(
            shares: shares, network: network, runner: runner ?? self.runner, files: files
        ) { [password] _ in password }
        let module = SambaModule(system: system, log: Log(writer: writer)) { [clock] in clock.now }
        module.apply(["server": .array(servers)])
        try await module.start()
        return module
    }

    private var logged: [String] { writer.entries.map(\.text.description) }

    @Test func reachableSharesMountWithTheKeychainPassword() async throws {
        shares.reachable.withLock { $0 = ["nas.local"] }
        let module = try await started([nas])
        #expect(shares.asked.withLock { $0 } == ["joris@nas.local/media secret", "joris@nas.local/backup secret"])
        #expect(logged == ["nas/media: mounted at /Volumes/media", "nas/backup: mounted at /Volumes/backup"])
        #expect(module.status == .running)
        #expect(network.isWatching)
    }

    @Test func unreachableServerMountsNothingAndIsNoProblem() async throws {
        let module = try await started([nas])
        #expect(shares.asked.withLock { $0 }.isEmpty)
        #expect(logged.first == "nas/media: not mounted, nas.local doesn't answer")
        #expect(module.status == .running)
    }

    @Test func missingPasswordShowsInTheMenuBar() async throws {
        shares.reachable.withLock { $0 = ["nas.local"] }
        _ = try password.remove()
        let module = try await started([nas])
        #expect(module.status == .degraded(reason: "nas/media: no password, run malum samba password nas"))
    }

    @Test func refusedPasswordSaysHowToChangeIt() async throws {
        shares.reachable.withLock { $0 = ["nas.local"] }
        shares.failure.withLock { $0 = .refused }
        let module = try await started([nas])
        let reason =
            "couldn't mount nas/media: the server refused the user or password, run malum samba password nas "
            + "to change it"
        #expect(module.status == .degraded(reason: reason))
    }

    @Test func takenVolumeIsLeftAlone() async throws {
        shares.reachable.withLock { $0 = ["nas.local"] }
        try files.createDirectory("/Volumes/media")
        let module = try await started([nas])
        #expect(shares.asked.withLock { $0 } == ["joris@nas.local/backup secret"])
        #expect(module.status == .degraded(reason: "nas/media: not mounted, /Volumes/media is already taken"))
    }

    @Test func networkChangeUnmountsSharesWhoseServerStoppedAnswering() async throws {
        shares.reachable.withLock { $0 = ["nas.local"] }
        let runner = runner
        let module = try await started([nas], runner: runner)
        shares.reachable.withLock { $0 = [] }
        network.change()
        await module.work?.value
        #expect(runner.commands == [Umount.force("/Volumes/media"), Umount.force("/Volumes/backup")])
        #expect(logged.last == "nas/backup: unmounted /Volumes/backup, nas.local stopped answering")
        #expect(shares.mounts().isEmpty)
    }

    @Test func checkLooksAgainOnlyAfterTheInterval() async throws {
        let module = try await started([nas])
        shares.reachable.withLock { $0 = ["nas.local"] }
        module.check()
        #expect(module.work == nil)
        clock.now += SambaModule.interval
        module.check()
        await module.work?.value
        #expect(shares.mounts().count == 2)
    }

    @Test func droppedShareIsUnmounted() async throws {
        shares.reachable.withLock { $0 = ["nas.local"] }
        let runner = runner
        let module = try await started([nas], runner: runner)
        let mediaOnly: ConfigValue = .table([
            "name": .string("nas"), "host": .string("nas.local"), "user": .string("joris"),
            "shares": .array([.string("media")]),
        ])
        module.apply(["server": .array([mediaOnly])])
        await module.work?.value
        #expect(runner.commands == [Umount.force("/Volumes/backup")])
        #expect(logged.contains("unmounted /Volumes/backup, its share is no longer in samba.toml"))
        #expect(shares.mounts().map(\.share) == ["media"])
    }

    @Test func stopLeavesSharesMountedAndStopsWatching() async throws {
        shares.reachable.withLock { $0 = ["nas.local"] }
        let module = try await started([nas])
        await module.stop()
        #expect(shares.mounts().count == 2)
        #expect(!network.isWatching)
        #expect(module.status == .off)
    }

    @Test func mountSourcesAreRead() {
        let mount = SambaMount(source: "//joris@NAS.local/my%20media", path: "/Volumes/my media")
        #expect(mount?.host == "nas.local")
        #expect(mount?.share == "my media")
        #expect(SambaMount(source: "/dev/disk3s1", path: "/") == nil)
        #expect(SambaMount(source: "//nas/media", path: "/Volumes/media")?.host == "nas")
    }

    @Test func mountStatusesAreNamed() {
        #expect(SambaMountError(status: 80) == .refused)
        #expect(SambaMountError(status: -6_003) == .refused)
        #expect(SambaMountError(status: 2) == .noShare)
        #expect(SambaMountError(status: 64) == .noAnswer)
        #expect(SambaMountError(status: 5) == .other(5))
    }
}

/// A time that tests move by hand.
@MainActor
private final class TestClock {
    var now = Date(timeIntervalSince1970: 1_000_000)
}
