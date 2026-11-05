/// An app whose config files and preferences system config writes from `apps/<name>.toml` in
/// dots: which files, in which format, from which tables.
struct AppConfig: Sendable {
    /// The table that holds the app's preferences.
    static let preferencesTable = "preferences"

    /// The app's name, which is also the name of its file in `apps/`.
    let name: String
    /// The preferences domain the table `preferences` is written to, such as `com.if.Amphetamine`,
    /// or nil when the app has none.
    let domain: String?
    /// The files the app gets.
    let files: [AppConfigFile]

    /// Creates the app called `name`, which gets `files`, and its preferences in `domain` when
    /// that's set.
    init(name: String, domain: String? = nil, files: [AppConfigFile] = []) {
        self.name = name
        self.domain = domain
        self.files = files
    }

    /// The files and preferences the app gets from its file in `apps/`, which `reader` holds,
    /// adding each problem found to `reader`.
    func read(_ reader: inout TableReader) -> (files: [AppFile], preferences: [AppPreference]) {
        let tables = files.flatMap(\.tables) + (domain == nil ? [] : [Self.preferencesTable])
        reader.unknownKeys(reader.document, at: [], known: tables)
        let appFiles = files.flatMap { $0.read(reader.document, app: name, reader: &reader) }
        guard let domain else { return (appFiles, []) }
        let table = reader.table(reader.document, Self.preferencesTable, at: [])
        let entries = reader.entries(
            table, at: [Self.preferencesTable], expected: "text, a number, true or false, or a list or table of them",
            write: PlistText.document)
        return (appFiles, entries.map { AppPreference(domain: domain, key: $0.key, value: $0.value) })
    }
}
