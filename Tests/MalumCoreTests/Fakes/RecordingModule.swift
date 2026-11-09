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
    let permissions: Set<Permission>
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
    /// What it offers the hotkey registry.
    var hotkeys = HotkeyOffer()
    /// What it offers once it's given settings, or nil to keep `hotkeys`.
    var hotkeysOnApply: HotkeyOffer?

    init(id: String, permissions: Set<Permission> = []) {
        self.id = id
        self.permissions = permissions
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

    func apply(_ settings: ModuleSettings) throws {
        calls.append("apply " + settings.table.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value.toml)" }.joined())
        if let hotkeysOnApply {
            hotkeys = hotkeysOnApply
        }
        guard !failsToApply else { throw FakeError.failed }
    }

    func stop() async {
        await Task.yield()
        calls.append("stop")
        status = .off
    }

    func check() {
        calls.append("check")
    }

    func resume() async {
        await Task.yield()
        calls.append("resume")
    }

    func perform(_ action: KeyAction) {
        calls.append("perform \(action)")
    }

    func modulesSwitched() {
        calls.append("modules switched")
    }
}
