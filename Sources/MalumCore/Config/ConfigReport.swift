/// What one load of `malum.toml` found.
public struct ConfigReport: Equatable, Sendable {
    /// The file that was loaded, or nil when it couldn't be read or parsed.
    public let loaded: String?
    /// The modules whose settings changed, which need them applied.
    public let changed: Set<String>
    /// The modules that keep their last good settings, because their table has a problem.
    public let kept: Set<String>
    /// Every problem found, in the order of the lines they're on.
    public let problems: [ConfigProblem]

    /// Creates a report.
    public init(loaded: String?, changed: Set<String>, kept: Set<String>, problems: [ConfigProblem]) {
        self.loaded = loaded
        self.changed = changed
        self.kept = kept
        self.problems = problems.sorted { ($0.line ?? Int.max) < ($1.line ?? Int.max) }
    }

    /// Everything the user should see, one message per line.
    public var messages: [Message] {
        let loadedMessage = loaded.map { [Message.loaded($0)] } ?? []
        let keptMessages = kept.sorted().map(Message.keepsLastGoodSettings)
        return loadedMessage + problems.map(\.message) + keptMessages
    }
}
