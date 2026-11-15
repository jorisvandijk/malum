import Synchronization
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LogCommandTests {
    /// Runs the command with `runner`, giving back whether it worked, what it wrote and what it reported.
    private func run(_ runner: FakeRunner, last: String?) async -> (Bool, [String], [Message]) {
        let written = Mutex<[String]>([])
        var messages: [Message] = []
        let succeeded = await LogCommand(runner: runner).run(
            last: last, write: { line in written.withLock { $0.append(line) } }, report: { messages.append($0) })
        return (succeeded, written.withLock { $0 }, messages)
    }

    @Test func entriesAreWrittenOneLineEach() async {
        let output = """
            Filtering the log data using "subsystem == ..."
            {"timestamp":"2026-11-15 09:00:00.1+0100","category":"app","eventMessage":"[info] running"}
            {"timestamp":"2026-11-15 09:00:02.5+0100","category":"samba","eventMessage":"[warn] couldn't mount"}
            """
        let runner = FakeRunner { _ in CommandResult(status: 0, output: output) }
        let (succeeded, written, messages) = await run(runner, last: nil)
        #expect(succeeded)
        #expect(runner.commands == [UnifiedLog.follow()])
        #expect(written == ["09:00:00 app [info] running", "09:00:02 samba [warn] couldn't mount"])
        #expect(messages.isEmpty)
    }

    @Test func lastShowsThatStretch() async {
        let runner = FakeRunner()
        let (succeeded, written, _) = await run(runner, last: "1h")
        #expect(succeeded)
        #expect(written.isEmpty)
        #expect(runner.commands == [UnifiedLog.show(last: "1h")])
    }

    @Test func failingLogIsReported() async {
        let runner = FakeRunner { _ in CommandResult(status: 64, errors: "log: bad predicate") }
        let (succeeded, _, messages) = await run(runner, last: "1h")
        #expect(!succeeded)
        #expect(messages == [Message(.error, "couldn't read the log: log: bad predicate")])
    }
}
