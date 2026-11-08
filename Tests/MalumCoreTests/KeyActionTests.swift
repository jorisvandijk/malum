import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct KeyActionTests {
    @Test func textWithADotIsAnApp() {
        #expect(KeyAction("com.apple.finder") == .app("com.apple.finder"))
    }

    @Test func textWithoutADotIsAModuleAction() {
        #expect(KeyAction("clipboard_history") == .module("clipboard_history"))
    }

    @Test func emptyTextIsNoAction() {
        #expect(KeyAction("") == nil)
    }
}
