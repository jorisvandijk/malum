import Observation

@testable import MalumCore

/// A module that writes down every call it gets, and fails the calls it's told to fail.
@Observable
@MainActor
final class RecordingModule: Module {
    /// What a failing call throws.
    enum FakeError: Error, CustomStringConvertible {
        case failed
        var description: String { "it broke" }
    }

    let id: String
    let permissions: Set<Permission> = []
    let schema = ConfigSchema(about: "Does nothing.", settings: ["size": Setting(.integer, "How big it is.")])
    private(set) var status = ModuleStatus.off
    /// Every call, in order, such as `apply size=1`, `start` or `stop`.
    private(set) var calls: [String] = []
    /// Whether `start` throws.
    var failsToStart = false
    /// Whether `apply` throws.
    var failsToApply = false
    /// Whether `cleanUp` throws.
    var failsToCleanUp = false

    init(id: String) {
        self.id = id
    }

    func cleanUp() async throws {
        await Task.yield()
        calls.append("clean up")
        guard !failsToCleanUp else { throw FakeError.failed }
    }

    func start() async throws {
        await Task.yield()
        calls.append("start")
        guard !failsToStart else { throw FakeError.failed }
        status = .running
    }

    func apply(_ config: ConfigTable) throws {
        calls.append("apply " + config.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value.toml)" }.joined())
        guard !failsToApply else { throw FakeError.failed }
    }

    func stop() async {
        await Task.yield()
        calls.append("stop")
        status = .off
    }
}
