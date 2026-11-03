/// What reading `malum.toml` gave, kept to tell whether anything changed since the last read.
enum ConfigSource: Equatable, Sendable {
    /// `malum init` hasn't recorded a dots folder.
    case noDots
    /// There's no `malum.toml` at the path.
    case missing(path: String)
    /// The file, or the record of where dots is, couldn't be read.
    case unreadable(FileSystemError)
    /// The file's path and text.
    case text(path: String, String)
}
