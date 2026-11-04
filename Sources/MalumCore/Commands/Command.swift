/// One run of an outside tool: its absolute path and its arguments. The command files build these,
/// so tests can check the exact command line without running anything.
public struct Command: Equatable, Sendable {
    /// The tool's absolute path.
    public let executable: String
    /// The arguments, without the tool itself.
    public let arguments: [String]
    /// Seconds the tool may run before it's stopped.
    public let timeoutSeconds: Int

    /// Seconds a tool may run, unless it waits for the user.
    public static let defaultTimeoutSeconds = 30

    /// Creates the run of `executable` with `arguments`, stopped after `timeoutSeconds`.
    public init(_ executable: String, _ arguments: [String], timeoutSeconds: Int = defaultTimeoutSeconds) {
        self.executable = executable
        self.arguments = arguments
        self.timeoutSeconds = timeoutSeconds
    }
}
