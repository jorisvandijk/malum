/// What one load of `malum.toml`, and the modules' own files, found.
public struct ConfigReport: Equatable, Sendable {
    /// The file that was loaded, or nil when it couldn't be read or parsed.
    public let loaded: String?
    /// The modules' own files whose settings were taken.
    public let moduleFiles: [String]
    /// The modules whose settings changed, which need them applied.
    public let changed: Set<String>
    /// The modules that keep their last good settings, because their table has a problem.
    public let kept: Set<String>
    /// Every problem found: those in `malum.toml` first, then those in each other file, each file's in
    /// the order of the lines they're on.
    public let problems: [ConfigProblem]

    /// Creates a report.
    public init(
        loaded: String?, moduleFiles: [String] = [], changed: Set<String>, kept: Set<String>,
        problems: [ConfigProblem]
    ) {
        self.loaded = loaded
        self.moduleFiles = moduleFiles
        self.changed = changed
        self.kept = kept
        self.problems = problems.sorted(by: Self.comesBefore)
    }

    /// Whether `first` is listed before `second`: `malum.toml` first, then the other files by name,
    /// and each file's problems by line.
    private static func comesBefore(_ first: ConfigProblem, _ second: ConfigProblem) -> Bool {
        guard first.file != second.file else { return (first.line ?? Int.max) < (second.line ?? Int.max) }
        switch Paths.configTOMLName {
        case first.file:
            return true
        case second.file:
            return false
        default:
            return first.file < second.file
        }
    }

    /// Everything the user should see, one message per line.
    public var messages: [Message] {
        let loadedMessage = loaded.map { [Message.loaded($0)] + moduleFiles.map(Message.loaded) } ?? []
        let keptMessages = kept.sorted().map(Message.keepsLastGoodSettings)
        return loadedMessage + problems.map(\.message) + keptMessages
    }
}
