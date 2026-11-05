/// An app whose config files system config writes from `apps/<name>.toml` in dots: which files,
/// in which format, from which tables.
struct AppConfig: Sendable {
    /// The app's name, which is also the name of its file in `apps/`.
    let name: String
    /// The files the app gets.
    let files: [AppConfigFile]

    /// The files the app gets from `table`, its file in `apps/`, and the problems found in it.
    func read(_ table: ConfigTable) -> (files: [AppFile], problems: [AppProblem]) {
        let known = files.flatMap(\.tables)
        var problems = AppTable.unknownKeys(table, at: [], known: known)
        var written: [AppFile] = []
        for file in files {
            written += file.read(table, app: name, problems: &problems)
        }
        return (written, problems)
    }
}
