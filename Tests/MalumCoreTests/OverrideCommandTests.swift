import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct OverrideCommandTests {
    let paths = Paths(home: "/Users/joris")
    var lock: String { "\(paths.stateDirectory)/app.lock" }
    var processIDFile: String { "\(paths.stateDirectory)/app.pid" }

    func command(_ files: FakeFileSystem, _ locks: FakeFileLocks, _ signals: FakeSignals) -> OverrideCommand {
        let state = StateFolder(files: files, locks: locks, paths: paths)
        return OverrideCommand(
            store: OverrideStore(state: state), instance: AppInstance(state: state, locks: locks), signals: signals)
    }

    @Test func safeTellsTheRunningApp() {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        let signals = FakeSignals()
        let messages = command(files, FakeFileLocks(heldElsewhere: [lock]), signals).safe()
        #expect(
            messages == [
                Message(.info, "safe mode is on: every module stays off until you leave it from the menu bar"),
                Message(.info, "asked Malum to reload"),
            ])
        #expect(files.text(at: "\(paths.stateDirectory)/safe-mode") == "asked\n")
        #expect(signals.sent == [4242])
    }

    @Test func disableWorksWithoutTheApp() {
        let files = FakeFileSystem()
        let messages = command(files, FakeFileLocks(), FakeSignals()).disable("launcher")
        #expect(
            messages == [
                Message(.info, "launcher stays off until you enable it from the menu bar"),
                Message(.info, "Malum isn't running, so this takes effect when it starts"),
            ])
        #expect(files.text(at: "\(paths.stateDirectory)/disabled") == "launcher\n")
    }

    @Test func failedSignalIsAnError() {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        let messages = command(files, FakeFileLocks(heldElsewhere: [lock]), FakeSignals(failing: [4242])).safe()
        #expect(messages.last == Message(.error, "couldn't signal Malum (process 4242): no such process"))
    }

    @Test func failedWriteIsAnErrorAndTellsNoOne() {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"], failing: ["\(paths.stateDirectory)/disabled"])
        let signals = FakeSignals()
        let messages = command(files, FakeFileLocks(heldElsewhere: [lock]), signals).disable("launcher")
        let path = "\(paths.stateDirectory)/disabled"
        #expect(messages == [Message(.error, "couldn't write \(private: path): read-only")])
        #expect(signals.sent.isEmpty)
    }
}
