import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TerminalAppTests {
    @Test func outsideATerminalThereIsNoName() {
        #expect(TerminalApp.name(environment: ["TERM_PROGRAM": "Apple_Terminal"], isTerminal: false) == nil)
    }

    @Test(arguments: [["KITTY_WINDOW_ID": "1"], ["TERM": "xterm-kitty"]])
    func kittyIsKnownByItsVariables(environment: [String: String]) {
        #expect(TerminalApp.name(environment: environment, isTerminal: true) == "kitty")
    }

    @Test func appleTerminalAndITermGetTheirOwnNames() {
        #expect(TerminalApp.name(environment: ["TERM_PROGRAM": "Apple_Terminal"], isTerminal: true) == "Terminal")
        #expect(TerminalApp.name(environment: ["TERM_PROGRAM": "iTerm.app"], isTerminal: true) == "iTerm")
    }

    @Test func otherTerminalIsCalledWhatItSays() {
        #expect(TerminalApp.name(environment: ["TERM_PROGRAM": "WezTerm"], isTerminal: true) == "WezTerm")
    }

    @Test func silentTerminalGetsAGeneralName() {
        #expect(TerminalApp.name(environment: [:], isTerminal: true) == "your terminal app")
    }
}
