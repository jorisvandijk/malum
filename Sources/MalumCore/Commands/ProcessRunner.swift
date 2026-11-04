import Foundation

/// Runs outside tools as real processes, with a clean environment and a timeout. stdout and stderr
/// are read at the same time, so a tool that fills one of them never blocks.
public struct ProcessRunner: CommandRunner {
    /// Seconds a tool may run before it's stopped.
    private static let timeoutSeconds = 30

    /// The only variables a tool gets.
    private let environment: [String: String]

    /// Creates the runner for the user whose home is `home`. Tools get only `HOME` and a fixed
    /// `PATH`, so nothing from the user's shell changes what they do.
    public init(home: String) {
        environment = ["HOME": home, "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]
    }

    /// Starts the tool, reads both of its outputs, and stops it when it runs past the timeout.
    public func run(_ command: Command) async -> CommandResult {
        let process = RunningProcess(command, environment: environment)
        async let output = Self.readAll(process.output)
        async let errors = Self.readAll(process.errors)
        let watchdog = Task {
            try await Task.sleep(for: .seconds(Self.timeoutSeconds))
            process.stop()
        }
        let status = await process.start()
        watchdog.cancel()
        let (outputText, errorText) = await (output, errors)
        guard let status else { return CommandResult(status: nil, errors: process.failure ?? errorText) }
        return CommandResult(status: status, output: outputText, errors: errorText)
    }

    /// Reads `handle` until the tool closes it. The read blocks, so it runs on its own queue and
    /// never ties up a thread of Swift's shared pool.
    private static func readAll(_ handle: FileHandle) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let data = handle.readDataToEndOfFile()
                continuation.resume(returning: String(bytes: data, encoding: .utf8) ?? "")
            }
        }
    }
}

/// A process and its pipes, shared between the runner and its timeout.
private final class RunningProcess: @unchecked Sendable {  // SAFETY: failure is set before start returns.
    /// The process.
    private let process = Process()
    /// The pipe for stdout.
    private let outputPipe = Pipe()
    /// The pipe for stderr.
    private let errorPipe = Pipe()
    /// Why the process couldn't start, once start has returned nil.
    private(set) var failure: String?

    /// Sets up `command` to run with `environment` and no input.
    init(_ command: Command, environment: [String: String]) {
        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments
        process.environment = environment
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = outputPipe
        process.standardError = errorPipe
    }

    /// The end of stdout that Malum reads.
    var output: FileHandle { outputPipe.fileHandleForReading }
    /// The end of stderr that Malum reads.
    var errors: FileHandle { errorPipe.fileHandleForReading }

    /// Starts the process and waits for it to end. Returns its exit status, or nil when it
    /// couldn't start or was stopped.
    func start() async -> Int32? {
        await withCheckedContinuation { continuation in
            process.terminationHandler = { process in
                let stopped = process.terminationReason == .uncaughtSignal
                continuation.resume(returning: stopped ? nil : process.terminationStatus)
            }
            do {
                try process.run()
            } catch {
                failure = "couldn't start \(process.executableURL?.path ?? "the tool"): \(error.localizedDescription)"
                // Nothing will write to the pipes, so closing them ends the reads.
                outputPipe.fileHandleForWriting.closeFile()
                errorPipe.fileHandleForWriting.closeFile()
                continuation.resume(returning: nil)
            }
        }
    }

    /// Stops the process when it's still running.
    func stop() {
        guard process.isRunning else { return }
        process.terminate()
    }
}
