import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TerminalAccessTests {
    @Test func terminalWithAccessIsReported() {
        let access = TerminalAccess(terminal: "kitty", check: FakePermissions())
        #expect(access.report() == Message(.info, "kitty has Full Disk Access"))
        #expect(!access.isMissing)
    }

    @Test func terminalWithoutAccessGetsAdvice() {
        let access = TerminalAccess(terminal: "kitty", check: FakePermissions([.fullDiskAccess: .missing]))
        let advice =
            "kitty doesn't have Full Disk Access, so macOS keeps asking kitty about what \(Project.command) does "
            + "in it; turn it on in System Settings > Privacy & Security > Full Disk Access, then quit and "
            + "reopen kitty"
        #expect(access.report() == Message(.warn, MessageText(advice)))
        #expect(access.isMissing)
    }

    @Test func accessThatCantBeToldIsSaid() {
        let access = TerminalAccess(terminal: "kitty", check: FakePermissions([.fullDiskAccess: .unknown]))
        #expect(access.report() == Message(.warn, "couldn't tell whether kitty has Full Disk Access"))
        #expect(!access.isMissing)
    }

    @Test func outsideATerminalNothingIsMissing() {
        let access = TerminalAccess(terminal: nil, check: FakePermissions([.fullDiskAccess: .missing]))
        #expect(access.report() == Message(.info, "not running in a terminal, so there's no terminal to check"))
        #expect(!access.isMissing)
    }
}
