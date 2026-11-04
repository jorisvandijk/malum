import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct PermissionCheckTests {
    @Test func onlyPermissionsKnownToBeMissingAreMissing() {
        let check = FakePermissions([.accessibility: .missing, .automation: .unknown])
        #expect(check.missing(from: [.accessibility, .automation, .screenRecording]) == [.accessibility])
    }
}
