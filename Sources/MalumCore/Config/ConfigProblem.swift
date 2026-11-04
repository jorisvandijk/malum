/// Something wrong with one of Malum's TOML files in dots, with the line it's on when that's known.
public struct ConfigProblem: Equatable, Sendable {
    /// How serious it is.
    public let level: Level
    /// The line the problem is on.
    public let line: Int?
    /// The column the problem is at, for syntax errors.
    public let column: Int?
    /// What's wrong.
    public let text: MessageText
    /// The name of the file it's in, such as `malum.toml`.
    public let file: String

    /// Creates a problem in `file` at `line` and `column`, when they're known.
    public init(
        _ level: Level, file: String = Paths.configTOMLName, line: Int? = nil, column: Int? = nil, _ text: MessageText
    ) {
        self.level = level
        self.file = file
        self.line = line
        self.column = column
        self.text = text
    }

    /// The problem as the user sees it, starting with where it is.
    public var message: Message {
        guard let line else { return Message(level, text) }
        guard let column else { return Message(level, "\(file) line \(line): \(text)") }
        return Message(level, "\(file) line \(line), column \(column): \(text)")
    }
}
