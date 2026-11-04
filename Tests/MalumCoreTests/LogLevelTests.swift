import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LogLevelTests {
    @Test func messageLevelsKeepTheirName() {
        #expect([Level.info, .warn, .error].map(LogLevel.init) == [.info, .warn, .error])
    }
}
