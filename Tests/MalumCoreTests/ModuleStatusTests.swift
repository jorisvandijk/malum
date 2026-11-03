import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ModuleStatusTests {
    @Test func onlyRunningAndDegradedAreActive() {
        let active: [ModuleStatus] = [.running, .degraded(reason: "bad table")]
        let inactive: [ModuleStatus] = [.off, .starting, .failed(reason: "boom"), .needsPermission([.accessibility])]
        #expect(active.allSatisfy { $0.isActive })
        #expect(!inactive.contains { $0.isActive })
    }

    @Test func descriptionGivesTheReason() {
        #expect(ModuleStatus.failed(reason: "no display").description == "failed: no display")
        #expect(ModuleStatus.degraded(reason: "line 3: unknown key").description == "degraded: line 3: unknown key")
    }

    @Test func missingPermissionsAreListedByName() {
        let status = ModuleStatus.needsPermission([.screenRecording, .accessibility])
        #expect(status.description == "needs Accessibility, Screen Recording")
    }
}
