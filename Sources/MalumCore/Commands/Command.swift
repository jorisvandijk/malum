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

    /// Seconds a tool may run, unless it waits for the user.
    public static let defaultTimeoutSeconds = 30

    /// Creates the run of `executable` with `arguments`, stopped after `timeoutSeconds`, and on the
    /// terminal when `onTerminal` is set.
    public init(
        _ executable: String, _ arguments: [String], timeoutSeconds: Int = defaultTimeoutSeconds,
        onTerminal: Bool = false
    ) {
        self.executable = executable
        self.arguments = arguments
        self.timeoutSeconds = timeoutSeconds
        self.onTerminal = onTerminal
    }
}
