import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct EscapingTests {
    let text = "a\"b\\c\nd\te\u{1}"

    @Test func allEscapesControlsAsUnicode() {
        #expect(Escaping.quoted(text, controls: .all) == "\"a\\\"b\\\\c\\nd\\te\\u0001\"")
    }

    @Test func breaksLeavesOtherControlsAlone() {
        #expect(Escaping.quoted(text, controls: .breaks) == "\"a\\\"b\\\\c\\nd\\te\u{1}\"")
    }

    @Test func noneEscapesOnlyQuotesAndBackslashes() {
        #expect(Escaping.quoted(text, controls: .none) == "\"a\\\"b\\\\c\nd\te\u{1}\"")
    }

    @Test func unicodeEscapesUseUppercaseHex() {
        #expect(Escaping.quoted("\u{1F}", controls: .all) == "\"\\u001F\"")
    }

    @Test func xmlEscapesMarkup() {
        #expect(Escaping.xml("a & <b>") == "a &amp; &lt;b&gt;")
    }

    @Test func shellLeavesSafeTextAlone() {
        #expect(Escaping.shell("/Users/test/.gitconfig") == "/Users/test/.gitconfig")
    }

    @Test func shellQuotesTextWithSpacesAndQuotes() {
        #expect(Escaping.shell("/a b/it's") == "'/a b/it'\\''s'")
    }
}
