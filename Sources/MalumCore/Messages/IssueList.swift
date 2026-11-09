/// Numbers every warning and error of a run as it's reported, and lists them all again at the end,
/// so no problem gets lost in a long run's output.
@MainActor
public final class IssueList {
    /// Where the messages go.
    private let report: (Message) -> Void
    /// The numbered issues so far.
    private var issues: [Message] = []

    /// Creates a list that passes every message on to `report`.
    public init(report: @escaping (Message) -> Void) {
        self.report = report
    }

    /// Reports `message`, with its number in front when it's a warning or an error.
    public func add(_ message: Message) {
        guard message.level != .info else {
            report(message)
            return
        }
        let numbered = Message.issue(issues.count + 1, message)
        issues.append(numbered)
        report(numbered)
    }

    /// Reports how many issues there were and each one again, or nothing when there were none.
    public func finish() {
        guard !issues.isEmpty else { return }
        report(.issueCount(issues))
        issues.forEach(report)
    }
}
