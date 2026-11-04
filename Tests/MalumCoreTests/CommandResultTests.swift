import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct CommandResultTests {
    @Test func zeroStatusSucceeds() {
        #expect(CommandResult(status: 0).succeeded)
        #expect(!CommandResult(status: 1).succeeded)
        #expect(!CommandResult(status: nil).succeeded)
    }

    @Test func reasonIsTheLastLineOfErrors() {
        let result = CommandResult(status: 1, errors: "first\nsecond: no such file\n")
        #expect(result.reason == "second: no such file")
    }

    @Test func silentFailureGivesItsStatus() {
        #expect(CommandResult(status: 3).reason == "exited with 3")
        #expect(CommandResult(status: nil).reason == "didn't finish")
    }
}
