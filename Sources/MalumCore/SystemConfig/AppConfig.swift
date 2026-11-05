/// An app whose config files system config writes from `apps/<name>.toml` in dots: which files,
/// in which format, from which tables.
struct AppConfig: Sendable {
    /// The app's name, which is also the name of its file in `apps/`.
    let name: String
    /// The files the app gets.
    let files: [AppConfigFile]

    /// The files the app gets from its file in `apps/`, which `reader` holds, adding each problem
    /// found to `reader`.
    func read(_ reader: inout TableReader) -> [AppFile] {
        reader.unknownKeys(reader.document, at: [], known: files.flatMap(\.tables))
        return files.flatMap { $0.read(reader.document, app: name, reader: &reader) }
    }
}
