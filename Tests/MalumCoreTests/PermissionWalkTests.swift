import Testing

@testable import MalumCore

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PermissionWalkTests {
    /// Thrown by a pause that stands for a cancelled walk.
    struct Cancelled: Error {}

    let permissions = FakePermissions([.accessibility: .missing, .screenRecording: .missing, .localNetwork: .unknown])

    /// A walk whose pause grants the last page opened, as the user does, or throws when `cancel` is set.
    private func walk(opened: @escaping (Permission) -> Void, report: @escaping (Message) -> Void, cancel: Bool = false)
        -> PermissionWalk
    {
        var last: Permission?
        return PermissionWalk(
            check: permissions,
            open: {
                last = $0
                opened($0)
            },
            pause: { [permissions] in
                guard !cancel else { throw Cancelled() }
                last.map { permissions.set($0, .granted) }
            },
            report: report)
    }

    @Test func eachMissingPermissionOpensInTurnUntilGranted() async {
        var opened: [Permission] = []
        var messages: [Message] = []
        let walk = walk(opened: { opened.append($0) }, report: { messages.append($0) })
        await walk.walk([.accessibility, .screenRecording])
        #expect(opened == [.accessibility, .screenRecording])
        #expect(
            messages == [
                .grantNext(.accessibility, number: 1, of: 2), .grantNext(.screenRecording, number: 2, of: 2),
                .everyPermissionGranted,
            ])
        #expect(permissions.state(of: .screenRecording) == .granted)
    }

    @Test func cancelledWalkStopsWithoutSayingDone() async {
        var messages: [Message] = []
        let walk = walk(opened: { _ in }, report: { messages.append($0) }, cancel: true)
        await walk.walk([.accessibility])
        #expect(messages == [.grantNext(.accessibility, number: 1, of: 1)])
    }

    @Test func startWalksOnlyWaitedForPermissionsMacOSCanSeeInSettingsOrder() async {
        var opened: [Permission] = []
        var messages: [Message] = []
        let walk = walk(opened: { opened.append($0) }, report: { messages.append($0) })
        walk.start(waiting: [
            "screenshots": [.screenRecording], "keyboard": [.accessibility, .inputMonitoring], "samba": [.localNetwork],
        ])
        while messages.last != .everyPermissionGranted { await Task.yield() }
        #expect(opened == [.accessibility, .screenRecording])
    }

    @Test func nothingWaitingSaysAllIsGranted() async {
        var messages: [Message] = []
        let walk = walk(opened: { _ in }, report: { messages.append($0) })
        walk.start(waiting: [:])
        while messages.isEmpty { await Task.yield() }
        #expect(messages == [.everyPermissionGranted])
    }
}
