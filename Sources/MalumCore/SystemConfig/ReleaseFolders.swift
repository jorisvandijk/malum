/// Where system config installs what GitHub releases hold, from the settings in `malum.toml`.
public struct ReleaseFolders: Equatable, Sendable {
    /// The key of the folder apps go in.
    static let appsKey = "release_apps"
    /// The key of the folder programs go in.
    static let programsKey = "release_programs"
    /// Where apps go when the setting is left out.
    static let defaultApps = "/Applications"
    /// Where programs go when the setting is left out.
    static let defaultPrograms = "~/.local/bin"

    /// The folder apps go in.
    public let apps: String
    /// The folder programs go in.
    public let programs: String

    /// Creates the folders from `settings`, the module's table, with `~` expanded by `paths`.
    public init(_ settings: ConfigTable, paths: Paths) {
        func folder(_ key: String, _ fallback: String) -> String {
            guard case .string(let path) = settings[key] else { return paths.resolve(fallback, relativeTo: paths.home) }
            return paths.resolve(path, relativeTo: paths.home)
        }
        apps = folder(Self.appsKey, Self.defaultApps)
        programs = folder(Self.programsKey, Self.defaultPrograms)
    }
}
