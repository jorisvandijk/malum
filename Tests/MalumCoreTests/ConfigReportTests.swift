import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ConfigReportTests {
    @Test func messagesListLoadProblemsByLineThenKeptModules() {
        let report = ConfigReport(
            loaded: "/dots/malum.toml", changed: [], kept: ["window_manager", "launcher"],
            problems: [
                ConfigProblem(.error, line: 9, "launcher.size should be a whole number"),
                ConfigProblem(.warn, line: 2, "unknown module samba"),
            ])
        #expect(
            report.messages == [
                Message(.info, "loaded /dots/malum.toml"),
                Message(.warn, "malum.toml line 2: unknown module samba"),
                Message(.error, "malum.toml line 9: launcher.size should be a whole number"),
                Message(.warn, "launcher keeps its last good settings"),
                Message(.warn, "window_manager keeps its last good settings"),
            ])
    }

    @Test func unloadedFileHasNoLoadedMessage() {
        let report = ConfigReport(
            loaded: nil, changed: [], kept: [], problems: [ConfigProblem(.error, line: 1, column: 2, "bad")])
        #expect(report.messages == [Message(.error, "malum.toml line 1, column 2: bad")])
    }
}
