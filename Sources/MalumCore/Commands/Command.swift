/// One run of an outside tool: its absolute path and its arguments. The command files build these,
/// so tests can check the exact command line without running anything.
public struct Command: Equatable, Sendable {
    /// The tool's absolute path.
    public let executable: String
    /// The arguments, without the tool itself.
    public let arguments: [String]
    /// Seconds the tool may run before it's stopped.
    public let timeoutSeconds: Int
    /// Whether the tool shares Malum's terminal instead of having its output read: it can ask for a
    /// password there, and what it writes shows up as it goes.
    public let onTerminal: Bool
    /// What the tool reads on stdin, or nil for nothing, so a secret never shows up in its arguments.
    public let input: String?

    /// Seconds a tool may run, unless it waits for the user.
    public static let defaultTimeoutSeconds = 30

    /// Creates the run of `executable` with `arguments`, stopped after `timeoutSeconds`, on the
    /// terminal when `onTerminal` is set, and reading `input` on stdin.
    public init(
        _ executable: String, _ arguments: [String], timeoutSeconds: Int = defaultTimeoutSeconds,
        onTerminal: Bool = false, input: String? = nil
    ) {
        self.executable = executable
        self.arguments = arguments
        self.timeoutSeconds = timeoutSeconds
        self.onTerminal = onTerminal
        self.input = input
    }
}
