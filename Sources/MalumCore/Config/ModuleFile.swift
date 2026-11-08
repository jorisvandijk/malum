/// What reading a module's own settings file in dots gave, such as `keyboard.toml`.
public enum ModuleFile: Equatable, Sendable {
    /// The file's path and text.
    case text(path: String, String)
    /// The file at `path` couldn't be read.
    case unreadable(path: String, FileSystemError)

    /// Where the file is.
    var path: String {
        switch self {
        case .text(let path, _), .unreadable(let path, _):
            path
        }
    }

    /// The file's text, or the problem that it couldn't be read, in the file named `name`.
    func text(named name: String) throws(ConfigProblem) -> String {
        switch self {
        case .text(_, let text):
            text
        case .unreadable(_, let error):
            throw ConfigProblem(.error, file: name, error.text)
        }
    }
}
