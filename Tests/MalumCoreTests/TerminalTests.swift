import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TerminalTests {
    @Test func colorPaintsOnlyTheTagWord() {
        #expect(Terminal.format(Message(.info, "all good"), color: true) == "[\u{1B}[32minfo\u{1B}[0m] all good")
        #expect(Terminal.format(Message(.warn, "careful"), color: true) == "[\u{1B}[33mwarn\u{1B}[0m] careful")
        #expect(Terminal.format(Message(.error, "broken"), color: true) == "[\u{1B}[31merror\u{1B}[0m] broken")
    }

    @Test func withoutColorTheMessageIsPlain() {
        #expect(Terminal.format(Message(.warn, "careful"), color: false) == "[warn] careful")
    }

    @Test func privatePartsStillShowInFull() {
        let message = Message(.info, "loaded \(private: "/dots/malum.toml")")
        #expect(Terminal.format(message, color: true) == "[\u{1B}[32minfo\u{1B}[0m] loaded /dots/malum.toml")
    }

    @Test func colorOnlyOnATerminal() {
        #expect(Terminal.wantsColor(isTerminal: true, environment: [:]))
        #expect(!Terminal.wantsColor(isTerminal: false, environment: [:]))
    }

    @Test func nonEmptyNoColorTurnsColorOff() {
        #expect(!Terminal.wantsColor(isTerminal: true, environment: ["NO_COLOR": "1"]))
        #expect(Terminal.wantsColor(isTerminal: true, environment: ["NO_COLOR": ""]))
    }
}
