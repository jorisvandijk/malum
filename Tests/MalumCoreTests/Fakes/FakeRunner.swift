import Synchronization

@testable import MalumCore

/// Runs nothing: answers each command from `answer` and remembers what it was asked to run.
final class FakeRunner: CommandRunner {
    /// Every command, in order.
    private let ran = Mutex<[Command]>([])
    /// What each command gives back.
    private let answer: @Sendable (Command) -> CommandResult

    /// Answers every command with success and no output, unless `answer` says otherwise.
    init(answer: @escaping @Sendable (Command) -> CommandResult = { _ in CommandResult(status: 0) }) {
        self.answer = answer
    }

    var commands: [Command] { ran.withLock { $0 } }

    func run(_ command: Command) async -> CommandResult {
        ran.withLock { $0.append(command) }
        return answer(command)
    }
}
