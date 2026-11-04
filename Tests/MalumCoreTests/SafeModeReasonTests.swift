import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct SafeModeReasonTests {
    @Test func crashLoopSaysHowOftenMalumStarted() {
        #expect(SafeModeReason.crashLoop.description == "Malum started 3 times within 2 minutes")
    }

    @Test func askedNamesTheCommand() {
        #expect(SafeModeReason.asked.description == "turned on with malum safe")
    }
}
