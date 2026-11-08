import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct HotkeyTests {
    @Test func descriptionJoinsModifiersInTheirOrderAndTheKey() throws {
        let key = try #require(Key.named("return"))
        #expect(Hotkey(modifiers: [.shift, .ctrl], key: key).description == "ctrl+shift+return")
    }

    @Test func allFourModifiersAreWrittenHyper() throws {
        let key = try #require(Key.named("space"))
        #expect(Hotkey(modifiers: Set(Modifier.allCases), key: key).description == "hyper+space")
    }
}
