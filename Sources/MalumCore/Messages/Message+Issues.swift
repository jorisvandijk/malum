// MARK: - Issues

extension Message {
    /// `message` with its number in the run in front, such as `[error] #2 couldn't install ...`.
    static func issue(_ number: Int, _ message: Message) -> Message {
        Message(message.level, "#\(number) \(message.text)")
    }

    /// The heading of the list at the end of a run, an error when any of `issues` is one.
    static func issueCount(_ issues: [Message]) -> Message {
        let level: Level = issues.contains { $0.level == .error } ? .error : .warn
        let noun = issues.count == 1 ? "issue" : "issues"
        return Message(level, "\(issues.count) \(noun) in this run:")
    }
}
