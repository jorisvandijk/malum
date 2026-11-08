/// The words for why an outside tool failed, which every area puts in its messages.
extension CommandResult {
    /// Why it failed, for a message: the last line it wrote to stderr, or its exit status.
    public var reason: String {
        let lastLine = errors.split(separator: "\n").last.map(String.init)
        guard let lastLine, !lastLine.isEmpty else { return status.map { "exited with \($0)" } ?? "didn't finish" }
        return lastLine
    }

    /// Why the tool at `executable` couldn't be started, kept as what it wrote to stderr.
    static func startFailure(_ executable: String, reason: String) -> String {
        "couldn't start \(executable): \(reason)"
    }
}
