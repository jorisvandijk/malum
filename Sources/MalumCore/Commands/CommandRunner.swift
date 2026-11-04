/// Runs outside tools. Everything Malum runs goes through one of these, so tests use a fake.
public protocol CommandRunner: Sendable {
    /// Runs `command` and waits for it to finish.
    func run(_ command: Command) async -> CommandResult
}
