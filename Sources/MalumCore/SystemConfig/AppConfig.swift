/// An app whose config files, preferences and extensions system config sets from
/// `apps/<name>.toml` in dots: which files, in which format, from which tables.
struct AppConfig: Sendable {
    /// The table that holds the app's preferences.
    static let preferencesTable = "preferences"
    /// The table that holds the app's system-wide preferences, such as a browser's policies.
    static let policiesTable = "policies"
    /// The table that lists the app's extensions, in `ids`.
    static let extensionsTable = "extensions"
    /// The key in `extensionsTable` that lists them.
    private static let extensionsKey = "ids"

    /// The app's name, which is also the name of its file in `apps/`.
    let name: String
    /// The preferences domain the table `preferences` is written to, such as `com.if.Amphetamine`,
    /// or nil when the app has none.
    let domain: String?
    /// The system-wide preferences domain the table `policies` is written to, such as
    /// `/Library/Preferences/net.librewolf.librewolf`, or nil when the app has none.
    let policies: String?
    /// The files the app gets.
    let files: [AppConfigFile]
    /// Where the extensions the app lists come from, or nil when it lists none.
    let extensions: AppExtensions?
    /// Whether the app keeps each preference as JSON in a data value, as apps that store them with
    /// Swift's `Codable` do.
    let jsonPreferences: Bool
    /// Whether the app is sandboxed: its files and preferences live in its container in
    /// `Library/Containers/<domain>`, which macOS makes when the app first opens.
    let sandboxed: Bool
    /// The app's curated tables, or nil when its file still holds the tables its files are written
    /// from as they are. With a catalog, the file holds only the catalog's tables (and `extensions`),
    /// and Malum translates them into what the files and preferences need.
    let catalog: Catalog?

    /// Creates the app called `name`, which gets `files`, its preferences in `domain` and its
    /// system-wide ones in `policies` when those are set, and the extensions it lists from
    /// `extensions` when that's set. Its preferences are written as JSON when it has
    /// `jsonPreferences`, and only once its container is there when it's `sandboxed`. With
    /// `catalog`, its file is read through the catalog's tables.
    init(
        name: String, domain: String? = nil, policies: String? = nil, files: [AppConfigFile] = [],
        extensions: AppExtensions? = nil, jsonPreferences: Bool = false, sandboxed: Bool = false,
        catalog: Catalog? = nil
    ) {
        self.name = name
        self.domain = domain
        self.policies = policies
        self.files = files
        self.extensions = extensions
        self.jsonPreferences = jsonPreferences
        self.sandboxed = sandboxed
        self.catalog = catalog
    }

    /// The app's container, relative to the home folder, or nil when it isn't sandboxed.
    var container: String? {
        guard sandboxed, let domain else { return nil }
        return Paths.container(of: domain)
    }

    /// What the app gets from its file in `apps/`, which `reader` holds, adding each problem found
    /// to `reader`. A path in the home folder is filled in with `home`.
    func read(_ reader: inout TableReader, home: String) -> AppSettings {
        let extensionTables = extensions == nil ? [] : [Self.extensionsTable]
        guard let catalog else {
            let tables = files.flatMap(\.tables) + preferenceTables.map(\.table) + extensionTables
            reader.unknownKeys(reader.document, at: [], known: tables)
            let appFiles = files.flatMap { $0.read(reader.document, app: name, reader: &reader) }
            return AppSettings(files: appFiles, preferences: preferences(&reader), extensions: extensionIDs(&reader))
        }
        reader.unknownKeys(reader.document, at: [], known: catalog.topTables + extensionTables)
        let document = jsonPreferences ? PlistText.jsonData : PlistText.document
        let reading = catalog.read(&reader, home: home, document: document)
        let tables = catalog.tables(reading.files, &reader)
        let appFiles = files.flatMap { $0.read(tables, app: name, reader: &reader) }
        let preferences = catalog.merged(reading.preferences, &reader)
        return AppSettings(files: appFiles, preferences: preferences, extensions: extensionIDs(&reader))
    }

    /// The tables of preferences the app has, each with the domain it's written to.
    private var preferenceTables: [(table: String, domain: String)] {
        [(Self.preferencesTable, domain), (Self.policiesTable, policies)].compactMap { table, domain in
            domain.map { (table, $0) }
        }
    }

    /// The preferences in the tables `preferences` and `policies`, none when the app has no domain.
    private func preferences(_ reader: inout TableReader) -> [AppPreference] {
        var preferences: [AppPreference] = []
        for (name, domain) in preferenceTables {
            let table = reader.table(reader.document, name, at: [])
            let entries = reader.entries(
                table, at: [name], expected: MessageText.plistValue,
                write: jsonPreferences ? PlistText.jsonData : PlistText.document)
            preferences += entries.map { AppPreference(domain: domain, key: $0.key, value: $0.value) }
        }
        return preferences
    }

    /// The extensions in `ids` of the table `extensions`, none when the app has no extensions.
    private func extensionIDs(_ reader: inout TableReader) -> [String] {
        guard let extensions else { return [] }
        let table = reader.table(reader.document, Self.extensionsTable, at: [])
        reader.unknownKeys(table, at: [Self.extensionsTable], known: [Self.extensionsKey])
        let path = [Self.extensionsTable, Self.extensionsKey]
        guard let value = table[Self.extensionsKey] else { return [] }
        guard let ids = TableReader.texts(value), ids.allSatisfy(extensions.isID) else {
            reader.expect(path, extensions.expected)
            return []
        }
        return ids
    }
}

/// What an app gets from its file in `apps/`.
struct AppSettings: Sendable {
    /// The config files to write.
    let files: [AppFile]
    /// The preferences to set.
    let preferences: [AppPreference]
    /// The extensions to install, by their ids.
    let extensions: [String]
}
