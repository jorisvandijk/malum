import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ModifierTests {
    @Test func namesAreInTheirOrderOrHyper() {
        #expect(Modifier.names(of: [.shift, .cmd]) == ["cmd", "shift"])
        #expect(Modifier.names(of: [.cmd, .option]) == ["option", "cmd"])
        #expect(Modifier.names(of: Set(Modifier.allCases)) == ["hyper"])
        #expect(Modifier.names(of: []).isEmpty)
    }
}
