/// One run of an outside tool: its absolute path and its arguments. The command files build these,
/// so tests can check the exact command line without running anything.
public struct Command: Equatable, Sendable {
    /// The tool's absolute path.
    public let executable: String
    /// The arguments, without the tool itself.
    public let arguments: [String]

    /// Creates the run of `executable` with `arguments`.
    public init(_ executable: String, _ arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }
}
