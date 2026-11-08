import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LogTests {
    @Test func entriesGoUnderTheAppCategoryByDefault() {
        let writer = RecordingLogWriter()
        Log(writer: writer).info("reloaded")
        #expect(writer.entries == [LogEntry(category: "app", level: .info, text: "reloaded")])
    }

    @Test func moduleLogUsesTheModuleIdAsCategory() {
        let writer = RecordingLogWriter()
        Log(writer: writer).module("launcher").debug("opened")
        #expect(writer.entries.map(\.category) == ["launcher"])
        #expect(writer.entries.map(\.level) == [.debug])
    }

    @Test func eachLevelHasItsOwnFunction() {
        let writer = RecordingLogWriter()
        let log = Log(writer: writer)
        log.debug("one")
        log.info("two")
        log.warn("three")
        log.error("four")
        #expect(writer.entries.map(\.level) == [.debug, .info, .warn, .error])
    }

    @Test func reportKeepsTheMessageLevelAndPrivateParts() {
        let writer = RecordingLogWriter()
        Log(writer: writer).report(Message(.warn, "couldn't watch \(private: "/Users/test/git/dots")"))
        #expect(writer.entries.map(\.redacted) == ["[warn] couldn't watch <private>"])
    }
}
