import Synchronization
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LogCommandTests {
    /// What one run gave: whether it worked, what it wrote and what it reported.
    private struct Outcome {
        let succeeded: Bool
        let written: [String]
        let messages: [Message]
    }

    /// Runs the command with `runner`.
    private func run(_ runner: FakeRunner, last: String?) async -> Outcome {
        let written = Mutex<[String]>([])
        var messages: [Message] = []
        let succeeded = await LogCommand(runner: runner).run(
            last: last, write: { line in written.withLock { $0.append(line) } }, report: { messages.append($0) })
        return Outcome(succeeded: succeeded, written: written.withLock { $0 }, messages: messages)
    }

    @Test func entriesAreWrittenOneLineEach() async {
        let output = """
            Filtering the log data using "subsystem == ..."
            {"timestamp":"2026-11-15 09:00:00.1+0100","category":"app","eventMessage":"[info] running"}
            {"timestamp":"2026-11-15 09:00:02.5+0100","category":"samba","eventMessage":"[warn] couldn't mount"}
            """
        let runner = FakeRunner { _ in CommandResult(status: 0, output: output) }
        let outcome = await run(runner, last: nil)
        #expect(outcome.succeeded)
        #expect(runner.commands == [UnifiedLog.follow()])
        #expect(outcome.written == ["09:00:00 app [info] running", "09:00:02 samba [warn] couldn't mount"])
        #expect(outcome.messages.isEmpty)
    }

    @Test func lastShowsThatStretch() async {
        let runner = FakeRunner()
        let outcome = await run(runner, last: "1h")
        #expect(outcome.succeeded)
        #expect(outcome.written.isEmpty)
        #expect(runner.commands == [UnifiedLog.show(last: "1h")])
    }

    @Test func failingLogIsReported() async {
        let runner = FakeRunner { _ in CommandResult(status: 64, errors: "log: bad predicate") }
        let outcome = await run(runner, last: "1h")
        #expect(!outcome.succeeded)
        #expect(outcome.messages == [Message(.error, "couldn't read the log: log: bad predicate")])
    }
}
