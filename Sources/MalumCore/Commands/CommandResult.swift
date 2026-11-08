/// What an outside tool did.
public struct CommandResult: Equatable, Sendable {
    /// The exit status, or nil when the tool couldn't be started or was stopped after the timeout.
    public let status: Int32?
    /// What it wrote to stdout.
    public let output: String
    /// What it wrote to stderr, or why it couldn't run.
    public let errors: String

    /// Creates a result.
    public init(status: Int32?, output: String = "", errors: String = "") {
        self.status = status
        self.output = output
        self.errors = errors
    }

    /// Whether the tool ran and exited with 0.
    public var succeeded: Bool { status == 0 }
}
