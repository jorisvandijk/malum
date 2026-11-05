/// Something wrong with one of Malum's TOML files in dots, with the line it's on when that's known.
public struct ConfigProblem: Error, Equatable, Sendable {
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
}
