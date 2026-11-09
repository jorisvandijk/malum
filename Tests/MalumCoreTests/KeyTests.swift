import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct KeyTests {
    @Test func everyDecidedNameIsAKey() {
        let letters = "abcdefghijklmnopqrstuvwxyz".map(String.init)
        let digits = (0...9).map(String.init)
        let functionKeys = (1...20).map { "f\($0)" }
        let named = [
            "return", "tab", "space", "delete", "delete_forward", "escape", "left", "right", "up", "down", "home",
            "end", "page_up", "page_down", "minus", "equal", "open_bracket", "close_bracket", "backslash",
            "semicolon", "quote", "grave", "comma", "period", "slash", "non_us_backslash", "caps_lock", "fn",
        ]
        let modifiers = ["control", "shift", "option", "command"].flatMap { ["left_\($0)", "right_\($0)"] }
        let names = letters + digits + functionKeys + named + modifiers
        #expect(Set(Key.all.map(\.name)) == Set(names))
        #expect(Key.all.count == names.count)
    }

    @Test func keyCodesAndUsagesAreEachUsedOnce() {
        #expect(Set(Key.all.map(\.keyCode)).count == Key.all.count)
        let usages = Key.all.flatMap(\.hidUsages)
        #expect(Set(usages).count == usages.count)
    }

    @Test func capsLockHasItsCodes() {
        let key = Key.named("caps_lock")
        #expect(key?.keyCode == 0x39)
        #expect(key?.hidUsages == [0x7_0000_0039])
    }

    @Test func fnIsSentOnBothApplePages() {
        #expect(Key.named("fn")?.hidUsages == [0xFF_0000_0003, 0xFF01_0000_0003])
    }

    @Test func unknownNameIsNoKey() {
        #expect(Key.named("enter") == nil)
        #expect(Key.named("Caps_Lock") == nil)
    }

    @Test func everyKeyIsFoundByItsCode() {
        #expect(Key.all.allSatisfy { Key.coded($0.keyCode) == $0 })
        #expect(Key.coded(.max) == nil)
    }

    @Test func hyperKeysAreTheDecidedOnes() {
        let names = ["caps_lock", "left_option", "right_option", "right_command"] + (13...20).map { "f\($0)" }
        #expect(Set(Key.hyperKeys.map(\.name)) == Set(names))
        #expect(Key.hyperKeys.count == names.count)
    }
}
