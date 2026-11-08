import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct AppInstanceTests {
    let paths = Paths(home: "/Users/test")
    var lock: String { "\(paths.stateDirectory)/app.lock" }
    var processIDFile: String { "\(paths.stateDirectory)/app.pid" }

    func instance(_ files: FakeFileSystem, _ locks: FakeFileLocks) -> AppInstance {
        AppInstance(state: StateFolder(files: files, locks: locks, paths: paths), locks: locks)
    }

    @Test func firstAppClaimsAndRecordsItsProcess() throws {
        let files = FakeFileSystem()
        let locks = FakeFileLocks()
        #expect(try instance(files, locks).claim(processID: 4242))
        #expect(locks.held == [lock])
        #expect(files.text(at: processIDFile) == "4242\n")
    }

    @Test func secondAppIsTurnedAway() throws {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        let locks = FakeFileLocks(heldElsewhere: [lock])
        #expect(try !instance(files, locks).claim(processID: 5353))
        #expect(files.text(at: processIDFile) == "4242\n")
    }

    @Test func claimFailsWhenLockFails() {
        let locks = FakeFileLocks(failing: [lock])
        #expect(throws: InstanceError.state(.unlockable(path: lock, reason: "permission denied"))) {
            try instance(FakeFileSystem(), locks).claim(processID: 4242)
        }
    }

    @Test func runningAppIsFound() throws {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        #expect(try instance(files, FakeFileLocks(heldElsewhere: [lock])).runningProcessID() == 4242)
    }

    @Test func leftoverProcessIDIsIgnored() {
        let files = FakeFileSystem(texts: [processIDFile: "4242\n"])
        #expect(throws: InstanceError.notRunning) {
            try instance(files, FakeFileLocks()).runningProcessID()
        }
    }

    @Test func missingProcessIDIsReported() {
        #expect(throws: InstanceError.noProcessID(path: processIDFile)) {
            try instance(FakeFileSystem(), FakeFileLocks(heldElsewhere: [lock])).runningProcessID()
        }
    }

    @Test func garbledProcessIDIsReported() {
        let files = FakeFileSystem(texts: [processIDFile: "not a number\n"])
        #expect(throws: InstanceError.noProcessID(path: processIDFile)) {
            try instance(files, FakeFileLocks(heldElsewhere: [lock])).runningProcessID()
        }
    }
}
