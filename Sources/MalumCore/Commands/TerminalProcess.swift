import Foundation

/// Runs a tool on Malum's own terminal, the way a shell does: it reads and writes the terminal
/// directly and stays in Malum's session, so `sudo` can ask for the password there and later
/// `sudo` runs on the same terminal don't ask again.
enum TerminalProcess {
    /// The bits of a wait status that name the signal that stopped the process.
    private static let signalBits: Int32 = 0x7f
    /// How far the exit status sits up in a wait status.
    private static let statusShift: Int32 = 8
    /// The bits of the exit status, once shifted down.
    private static let statusBits: Int32 = 0xff

    /// Starts `command` with only `environment`, waits for it to end, and stops it when it runs
    /// past the timeout. Gives its exit status, or nil when it couldn't start or was stopped.
    static func run(_ command: Command, environment: [String: String]) async -> CommandResult {
        let arguments = ([command.executable] + command.arguments).map { strdup($0) } + [nil]
        let variables = environment.map { strdup("\($0.key)=\($0.value)") } + [nil]
        var pid: pid_t = 0
        let started = posix_spawn(&pid, command.executable, nil, nil, arguments, variables)
        for pointer in arguments + variables { free(pointer) }
        guard started == 0 else {
            let reason = String(cString: strerror(started))
            return CommandResult(status: nil, errors: CommandResult.startFailure(command.executable, reason: reason))
        }
        let child = pid
        let watchdog = Task {
            try await Task.sleep(for: .seconds(command.timeoutSeconds))
            kill(child, SIGTERM)
        }
        let status = await exitStatus(of: child)
        watchdog.cancel()
        return CommandResult(status: status)
    }

    /// Waits for `pid` to end, on its own queue since the wait blocks. Gives its exit status, or nil
    /// when a signal stopped it.
    private static func exitStatus(of pid: pid_t) async -> Int32? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                var status: Int32 = 0
                var ended: pid_t
                repeat {
                    ended = waitpid(pid, &status, 0)
                } while ended < 0 && errno == EINTR
                guard ended == pid, status & signalBits == 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (status >> statusShift) & statusBits)
            }
        }
    }
}
