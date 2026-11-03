import Observation
import TOMLKit
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ModuleTests {
    @Test func moduleMovesThroughItsStatuses() async throws {
        let module = FakeModule()
        #expect(module.status == .off)
        try await module.start()
        #expect(module.status == .running)
        await module.stop()
        #expect(module.status == .off)
    }

    @Test func badConfigFailsOnlyThatCall() async throws {
        let module = FakeModule()
        try await module.start()
        let table = try TOMLReader.table(from: "enabled = \"yes\"")
        #expect(throws: FakeModule.FakeError.self) { try module.apply(table) }
        #expect(module.status == .degraded(reason: "enabled is not a boolean"))
    }

    @Test func statusChangesAreObserved() async throws {
        let module = FakeModule()
        let changed = Changed()
        withObservationTracking {
            _ = module.status
        } onChange: {
            changed.mark()
        }
        try await module.start()
        #expect(changed.happened)
    }
}

/// Records that an observation fired.
private final class Changed: @unchecked Sendable {  // SAFETY: only touched on the main actor in these tests.
    private(set) var happened = false
    func mark() { happened = true }
}

/// A module that only tracks its status, to check the contract can be met.
@Observable
@MainActor
private final class FakeModule: Module {
    enum FakeError: Error { case notBoolean }

    let id = "fake"
    let permissions: Set<Permission> = [.accessibility]
    private(set) var status = ModuleStatus.off

    func start() async throws { status = .running }

    func apply(_ config: TOMLTable) throws {
        guard config["enabled"]?.bool != nil else {
            status = .degraded(reason: "enabled is not a boolean")
            throw FakeError.notBoolean
        }
        status = .running
    }

    func stop() async { status = .off }
}
