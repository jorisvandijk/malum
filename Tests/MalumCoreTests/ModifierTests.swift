import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ModifierTests {
    @Test func tableJoinsModifiersInTheirOrder() {
        #expect(Modifier.table(of: [.shift, .ctrl]) == "ctrl_shift")
        #expect(Modifier.table(of: [.cmd, .option]) == "option_cmd")
        #expect(Modifier.table(of: [.cmd]) == "cmd")
    }

    @Test func allFourIsHyper() {
        #expect(Modifier.table(of: Set(Modifier.allCases)) == "hyper")
    }

    @Test func tableNameInAnyOrderGivesItsModifiers() {
        #expect(Modifier.modifiers(inTable: "ctrl_shift") == [.ctrl, .shift])
        #expect(Modifier.modifiers(inTable: "shift_ctrl") == [.ctrl, .shift])
        #expect(Modifier.modifiers(inTable: "hyper") == Set(Modifier.allCases))
    }

    @Test func otherNamesAreNoModifiers() {
        #expect(Modifier.modifiers(inTable: "control") == nil)
        #expect(Modifier.modifiers(inTable: "ctrl_ctrl") == nil)
        #expect(Modifier.modifiers(inTable: "ctrl__shift") == nil)
        #expect(Modifier.modifiers(inTable: "") == nil)
    }
}
