import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct MessageTextTests {
    @Test func descriptionShowsPrivatePartsToo() {
        let text: MessageText = "couldn't read \(private: "/Users/joris/git/dots"): no such file"
        #expect(text.description == "couldn't read /Users/joris/git/dots: no such file")
    }

    @Test func redactedHidesPrivateParts() {
        let text: MessageText = "dots moved from \(private: "/old") to \(private: "/new")"
        #expect(text.redacted == "dots moved from <private> to <private>")
        #expect(text.hidden == ["/old", "/new"])
    }

    @Test func plainValuesStayPublic() {
        let text: MessageText = "started \("launcher") after \(2) tries"
        #expect(text.redacted == "started launcher after 2 tries")
        #expect(text.hidden.isEmpty)
    }

    @Test func nestedTextKeepsItsPrivateParts() {
        let inner: MessageText = "couldn't lock \(private: "/tmp/state.lock")"
        let outer: MessageText = "\(inner): permission denied"
        #expect(outer.redacted == "couldn't lock <private>: permission denied")
    }

    @Test func textsThatReadTheSameAreEqual() {
        #expect(MessageText("linked /a") == "linked \(private: "/a")")
    }
}
