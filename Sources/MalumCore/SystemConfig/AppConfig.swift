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
    /// Whether the app lists extensions to install, as VSCodium does.
    let extensions: Bool

    /// Creates the app called `name`, which gets `files`, its preferences in `domain` and its
    /// system-wide ones in `policies` when those are set, and the extensions it lists when it has
    /// `extensions`.
    init(
        name: String, domain: String? = nil, policies: String? = nil, files: [AppConfigFile] = [],
        extensions: Bool = false
    ) {
        self.name = name
        self.domain = domain
        self.policies = policies
        self.files = files
        self.extensions = extensions
    }

    /// What the app gets from its file in `apps/`, which `reader` holds, adding each problem found
    /// to `reader`.
    func read(_ reader: inout TableReader) -> AppSettings {
        let tables =
            files.flatMap(\.tables) + preferenceTables.map(\.table) + (extensions ? [Self.extensionsTable] : [])
        reader.unknownKeys(reader.document, at: [], known: tables)
        let appFiles = files.flatMap { $0.read(reader.document, app: name, reader: &reader) }
        return AppSettings(files: appFiles, preferences: preferences(&reader), extensions: extensionIDs(&reader))
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
            let entries = reader.entries(table, at: [name], expected: MessageText.plistValue, write: PlistText.document)
            preferences += entries.map { AppPreference(domain: domain, key: $0.key, value: $0.value) }
        }
        return preferences
    }

    /// The extensions in `ids` of the table `extensions`, as `publisher.name`, none when the app
    /// has no extensions.
    private func extensionIDs(_ reader: inout TableReader) -> [String] {
        guard extensions else { return [] }
        let table = reader.table(reader.document, Self.extensionsTable, at: [])
        reader.unknownKeys(table, at: [Self.extensionsTable], known: [Self.extensionsKey])
        let path = [Self.extensionsTable, Self.extensionsKey]
        guard let value = table[Self.extensionsKey] else { return [] }
        guard let ids = TableReader.texts(value), ids.allSatisfy(Codium.isExtensionID) else {
            reader.expect(path, MessageText.extensionList)
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
    /// The extensions to install, as `publisher.name`.
    let extensions: [String]
}
