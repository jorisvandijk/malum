/// One run's sudo: the first part that needs root asks for the password, every later part gets the
/// same answer without asking again, and the password stays remembered until the run ends.
@MainActor
public final class SudoSession {
    /// Seconds between refreshes, well inside sudo's five minutes.
    private static let refreshSeconds = 60

    /// Runs `sudo`.
    private let runner: any CommandRunner
    /// Whether Malum runs in a terminal, where sudo can ask.
    private let canAsk: Bool
    /// Whether root was granted, or nil until something asked.
    private var granted: Bool?
    /// Keeps the password remembered while the run goes on.
    private var keepAlive: Task<Void, Never>?

    /// Creates the session, which runs `sudo` through `runner` and asks only when `canAsk` is set.
    public init(runner: any CommandRunner, canAsk: Bool) {
        self.runner = runner
        self.canAsk = canAsk
    }

    /// Asks for the password the first time, saying it's for `reason`, and gives the same answer
    /// after that. Says whether root was granted.
    public func authorize(for reason: MessageText, report: (Message) -> Void) async -> Bool {
        if let granted { return granted }
        guard canAsk else {
            report(.passwordNeedsTerminal(for: reason))
            granted = false
            return false
        }
        report(.askingForPassword(for: reason))
        let result = await runner.run(Sudo.authorize)
        granted = result.succeeded
        guard result.succeeded else {
            report(.passwordRefused(for: reason))
            return false
        }
        keepAlive = Task { [runner] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.refreshSeconds))  // Only fails when cancelled.
                guard !Task.isCancelled else { return }
                _ = await runner.run(Sudo.refresh)
            }
        }
        return true
    }

    /// Stops keeping the password remembered. The run calls this once it's done.
    public func end() {
        keepAlive?.cancel()
        keepAlive = nil
    }
}
