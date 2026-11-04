/// Something wrong in an app's file in `apps/`, at the key `path`.
struct AppProblem: Equatable, Sendable {
    /// How serious it is. An error stops the app's files from being written.
    let level: Level
    /// The key it's about, from the top of the file.
    let path: [String]
    /// What's wrong.
    let text: String

    /// Creates a problem of `level` at the key `path`.
    init(_ level: Level, at path: [String], _ text: String) {
        self.level = level
        self.path = path
        self.text = text
    }
}
