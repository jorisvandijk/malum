/// An app whose config files system config writes from `apps/<name>.toml` in dots.
protocol AppConfig: Sendable {
    /// The app's name, which is also the name of its file in `apps/`.
    var name: String { get }

    /// The files the app gets from `table`, its file in `apps/`, and the problems found in it.
    func read(_ table: ConfigTable) -> (files: [AppFile], problems: [AppProblem])
}

extension AppConfig {
    /// The line at the top of each file, behind the format's comment `mark`, that says where it
    /// comes from.
    func header(_ mark: String) -> String {
        "\(mark) Written by \(Project.name) from \(Paths.appsFolderName)/\(name).toml in dots. "
            + "Changes made here are overwritten.\n"
    }

    /// A warning for each key of `table`, found at `path`, that isn't in `known`.
    func unknownKeys(_ table: ConfigTable, at path: [String] = [], known: [String]) -> [AppProblem] {
        table.keys.sorted().filter { !known.contains($0) }.map { key in
            AppProblem(.warn, at: path + [key], "unknown setting \(dotted(path + [key]))")
        }
    }

    /// `path` as a dotted key, such as `settings.user`.
    func dotted(_ path: [String]) -> String {
        path.map(ConfigValue.key).joined(separator: ".")
    }
}
