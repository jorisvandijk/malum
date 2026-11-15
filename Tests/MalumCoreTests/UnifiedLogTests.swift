import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct UnifiedLogTests {
    private let predicate = "subsystem == \"\(Project.bundleID)\""

    @Test func followStreamsMalumsEntriesAsJSON() {
        let command = UnifiedLog.follow()
        #expect(command.executable == "/usr/bin/log")
        #expect(command.arguments == ["stream", "--style", "ndjson", "--level", "info", "--predicate", predicate])
    }

    @Test func showReadsTheStretchAsked() {
        #expect(
            UnifiedLog.show(last: "2h").arguments == [
                "show", "--style", "ndjson", "--info", "--last", "2h", "--predicate", predicate,
            ])
    }

    @Test func stretchIsANumberAndAUnit() {
        #expect(["30s", "15m", "1h", "2d"].allSatisfy(UnifiedLog.isStretch))
        #expect(!["", "h", "1", "1w", "-1h", "1.5h", "٣h"].contains(where: UnifiedLog.isStretch))
    }

    @Test func entryKeepsTimeCategoryAndText() {
        let line = """
            {"timestamp":"2026-11-15 00:12:01.234567+0100","category":"keyboard",\
            "eventMessage":"[info] remaps set again","processID":812}
            """
        #expect(
            UnifiedLog.entry(line) == LogLine(time: "00:12:01", category: "keyboard", text: "[info] remaps set again"))
        #expect(UnifiedLog.entry(line)?.description == "00:12:01 keyboard [info] remaps set again")
    }

    @Test func privateValuesAtTheEndAreLeftOut() {
        let line = """
            {"timestamp":"2026-11-15 00:12:01.234567+0100","category":"app",\
            "eventMessage":"[info] loaded <private> <private>"}
            """
        #expect(UnifiedLog.entry(line)?.text == "[info] loaded <private>")
    }

    @Test func linesThatArentEntriesAreSkipped() {
        #expect(UnifiedLog.entry("Filtering the log data using \"subsystem == ...\"") == nil)
        #expect(UnifiedLog.entry("{\"count\":3,\"finished\":1}") == nil)
        #expect(UnifiedLog.entry("") == nil)
    }
}
