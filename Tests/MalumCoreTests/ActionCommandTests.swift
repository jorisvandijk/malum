import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ActionCommandTests {
    let paths = Paths(home: "/Users/test")
    var lock: String { "\(paths.stateDirectory)/app.lock" }
    var processIDFile: String { "\(paths.stateDirectory)/app.pid" }
    var requestsFile: String { "\(paths.stateDirectory)/action-requests" }

    func run(_ files: FakeFileSystem, _ locks: FakeFileLocks, _ signals: FakeSignals) -> Message {
        let state = StateFolder(files: files, locks: locks, paths: paths)
        let command = ActionCommand(
            instance: AppInstance(state: state, locks: locks), requests: ActionRequests(state: state), signals: signals)
        return command.run("screenshot")
    }

    @Test func runningAppGetsTheRequestAndTheSignal() throws {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        let signals = FakeSignals()
        let locks = FakeFileLocks(heldElsewhere: [lock])
        #expect(run(files, locks, signals) == Message(.info, "asked Malum for screenshot"))
        #expect(signals.asked == [4242] && signals.sent.isEmpty)
        let requests = ActionRequests(state: StateFolder(files: files, locks: locks, paths: paths))
        #expect(try requests.take() == ["screenshot"])
        #expect(try requests.take() == [])
    }

    @Test func noAppIsReportedAndNothingIsLeft() {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        let signals = FakeSignals()
        #expect(run(files, FakeFileLocks(), signals) == Message(.error, "couldn't reach Malum: it isn't running"))
        #expect(signals.asked.isEmpty)
        #expect(files.item(at: requestsFile) == nil)
    }

    @Test func requestsWaitInOrder() throws {
        let state = StateFolder(files: FakeFileSystem(), locks: FakeFileLocks(), paths: paths)
        let requests = ActionRequests(state: state)
        try requests.add("screenshot")
        try requests.add("launcher")
        #expect(try requests.take() == ["screenshot", "launcher"])
    }
}
