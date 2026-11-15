/// Runs outside tools. Everything Malum runs goes through one of these, so tests use a fake.
public protocol CommandRunner: Sendable {
    /// Runs `command` and waits for it to finish.
    func run(_ command: Command) async -> CommandResult
    /// Runs `command`, handing each line of its output to `each` as it comes, and waits for it to
    /// finish. The result's output is empty.
    func lines(of command: Command, each: @escaping @Sendable (String) -> Void) async -> CommandResult
}

extension CommandRunner {
    /// Runs `command` to the end, then hands over each line of its output.
    public func lines(of command: Command, each: @escaping @Sendable (String) -> Void) async -> CommandResult {
        let result = await run(command)
        for line in result.output.split(separator: "\n") {
            each(String(line))
        }
        return CommandResult(status: result.status, errors: result.errors)
    }
}
