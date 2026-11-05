/// The settings from `malum.toml`, keeping each module's last good table.
///
/// A problem in one module's table affects only that module: it keeps the settings it had, and
/// the other modules take their new ones as normal.
public struct Config: Sendable {
    /// Each module's schema, by the module's id.
    private let schemas: [String: ConfigSchema]
    /// Each module's last good settings, by the module's id, without `enabled`.
    public private(set) var settings: [String: ConfigTable] = [:]
    /// The modules whose last good table switches them on.
    public private(set) var enabled: Set<String> = []

    /// Creates a config with no settings yet, for the modules with these schemas.
    public init(schemas: [String: ConfigSchema]) {
        self.schemas = schemas
    }

    /// The ids of the modules this config holds settings for.
    public var modules: Set<String> { Set(schemas.keys) }

    /// Checks `text`, read from `path`, and takes the settings of every module whose table is fine.
    public mutating func load(_ text: String, from path: String) -> ConfigReport {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.configTOMLName)
        } catch {
            return ConfigReport(loaded: nil, changed: [], kept: modules, problems: [error])
        }
        let document = reader.document
        for key in document.keys.sorted() where schemas[key] == nil {
            let text: MessageText =
                if case .table? = document[key] { "unknown module \(key)" } else {
                    "\(key) isn't inside a module's table"
                }
            reader.add(.warn, at: [key], text)
        }
        var changed: Set<String> = []
        var kept: Set<String> = []
        for (module, schema) in schemas {
            guard let value = document[module] else {
                take([:], for: module, changed: &changed)
                continue
            }
            let before = reader.problems.count
            if let table = reader.table(value, at: [module]) {
                for (key, text) in schema.problems(in: table, module: module) {
                    reader.add(.error, at: [module, key], MessageText(text))
                }
            }
            guard reader.problems.count == before, case .table(let table) = value else {
                kept.insert(module)
                continue
            }
            take(table, for: module, changed: &changed)
        }
        return ConfigReport(loaded: path, changed: changed, kept: kept, problems: reader.problems)
    }

    /// Takes `table` as the settings of `module`, adding it to `changed` when they differ from the
    /// last ones.
    private mutating func take(_ table: ConfigTable, for module: String, changed: inout Set<String>) {
        var table = table
        let switchedOn = table.removeValue(forKey: ConfigSchema.switchKey) == .boolean(true)
        if settings[module] != table { changed.insert(module) }
        settings[module] = table
        if switchedOn { enabled.insert(module) } else { enabled.remove(module) }
    }
}
