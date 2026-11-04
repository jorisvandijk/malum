import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LogEntryTests {
    @Test func descriptionStartsWithTagAndShowsEverything() {
        let entry = LogEntry(category: "app", level: .error, text: "couldn't read \(private: "/a"): gone")
        #expect(entry.description == "[error] couldn't read /a: gone")
        #expect(entry.redacted == "[error] couldn't read <private>: gone")
    }
}
