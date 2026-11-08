/// What reading `malum.toml` and the modules' own files gave, kept to tell whether anything changed since the last read.
enum ConfigSource: Equatable, Sendable {
    /// `malum init` hasn't recorded a dots folder.
    case noDots
    /// There's no `malum.toml` at the path.
    case missing(path: String)
    /// The file, or the record of where dots is, couldn't be read.
    case unreadable(FileSystemError)
    /// The file's path and text, and each module's own file that's there, by the module's id.
    case text(path: String, String, modules: [String: ModuleFile])
}
