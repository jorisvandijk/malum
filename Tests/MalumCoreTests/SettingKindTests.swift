import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct SettingKindTests {
    @Test func numberAcceptsWholeNumbersAndFractions() {
        #expect(SettingKind.number.accepts(.integer(1)))
        #expect(SettingKind.number.accepts(.float(1.5)))
        #expect(!SettingKind.number.accepts(.string("1")))
    }

    @Test func integerRefusesFractions() {
        #expect(SettingKind.integer.accepts(.integer(1)))
        #expect(!SettingKind.integer.accepts(.float(1.5)))
    }

    @Test func stringsNeedsEveryItemToBeText() {
        #expect(SettingKind.strings.accepts(.array([])))
        #expect(SettingKind.strings.accepts(.array([.string("a"), .string("b")])))
        #expect(!SettingKind.strings.accepts(.array([.string("a"), .integer(1)])))
        #expect(!SettingKind.strings.accepts(.string("a")))
    }

    @Test func otherKindsTakeOnlyTheirOwnValue() {
        #expect(SettingKind.boolean.accepts(.boolean(false)))
        #expect(!SettingKind.boolean.accepts(.string("false")))
        #expect(SettingKind.string.accepts(.string("a")))
        #expect(SettingKind.table.accepts(.table([:])))
        #expect(!SettingKind.table.accepts(.array([])))
    }

    @Test func descriptionUsesPlainWords() {
        #expect(SettingKind.boolean.description == "true or false")
        #expect(SettingKind.strings.description == "a list of text in quotes")
    }
}
