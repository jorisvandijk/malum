import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ReloadCommandTests {
    let paths = Paths(home: "/Users/test")
    var lock: String { "\(paths.stateDirectory)/app.lock" }
    var processIDFile: String { "\(paths.stateDirectory)/app.pid" }

    func run(_ files: FakeFileSystem, _ locks: FakeFileLocks, _ signals: FakeSignals) -> Message {
        let instance = AppInstance(state: StateFolder(files: files, locks: locks, paths: paths), locks: locks)
        return ReloadCommand(instance: instance, signals: signals).run()
    }

    @Test func runningAppGetsHangUp() {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        let signals = FakeSignals()
        #expect(run(files, FakeFileLocks(heldElsewhere: [lock]), signals) == Message(.info, "asked Malum to reload"))
        #expect(signals.sent == [4242])
    }

    @Test func noAppIsReported() {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        let signals = FakeSignals()
        #expect(
            run(files, FakeFileLocks(), signals) == Message(.error, "couldn't reach Malum: it isn't running"))
        #expect(signals.sent.isEmpty)
    }

    @Test func failedSignalIsReported() {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        let signals = FakeSignals(failing: [4242])
        #expect(
            run(files, FakeFileLocks(heldElsewhere: [lock]), signals)
                == Message(.error, "couldn't signal Malum (process 4242): no such process"))
    }

    @Test func missingProcessIDIsReported() {
        #expect(
            run(FakeFileSystem(), FakeFileLocks(heldElsewhere: [lock]), FakeSignals())
                == Message(.error, "couldn't reach Malum: no process ID in \(processIDFile)"))
    }
}
