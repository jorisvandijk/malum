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

    /// Checks `text`, read from `path`, and each module's own file in `moduleFiles`, by the module's id,
    /// and takes the settings of every module whose settings are fine.
    public mutating func load(
        _ text: String, from path: String, moduleFiles: [String: ModuleFile] = [:]
    ) -> ConfigReport {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.configTOMLName)
        } catch {
            return ConfigReport(loaded: nil, changed: [], kept: modules, problems: [error])
        }
        let document = reader.document
        for key in document.keys.sorted() where schemas[key] == nil {
            let text: MessageText =
                if case .table? = document[key] { .unknownModule(key) } else { .outsideModule(key) }
            reader.add(.warn, at: [key], text)
        }
        var changed: Set<String> = []
        var kept: Set<String> = []
        var fileProblems: [ConfigProblem] = []
        for (module, schema) in schemas {
            let file = moduleFiles[module]
            let table = moduleSettings(of: module, schema: schema, file: file, in: &reader, problems: &fileProblems)
            guard let table else {
                kept.insert(module)
                continue
            }
            take(table, for: module, changed: &changed)
        }
        let loadedFiles = moduleFiles.filter { !kept.contains($0.key) }.map(\.value.path).sorted()
        return ConfigReport(
            loaded: path, moduleFiles: loadedFiles, changed: changed, kept: kept,
            problems: reader.problems + fileProblems)
    }

    /// The settings of `module`, from its table in `malum.toml` that `reader` reads and from its own
    /// `file` when there is one, or nil when either has a problem. The own file's problems go in `problems`.
    private func moduleSettings(
        of module: String, schema: ConfigSchema, file: ModuleFile?, in reader: inout TableReader,
        problems: inout [ConfigProblem]
    ) -> ConfigTable? {
        guard let table = checkedTable(of: module, schema: schema, in: &reader) else { return nil }
        guard let file else { return table }
        guard table.keys.allSatisfy({ $0 == ConfigSchema.switchKey }) else {
            reader.add(.error, at: [module], .settingsInTwoPlaces(module))
            return nil
        }
        guard let settings = fileSettings(of: module, schema: schema, from: file, problems: &problems) else {
            return nil
        }
        return table.merging(settings) { switchValue, _ in switchValue }
    }

    /// The table of `module` in `malum.toml`, which `reader` reads, checked against `schema`. Empty
    /// when it's missing, nil when it has a problem.
    private func checkedTable(of module: String, schema: ConfigSchema, in reader: inout TableReader) -> ConfigTable? {
        guard let value = reader.document[module] else { return [:] }
        let before = reader.problems.count
        if let table = reader.table(value, at: [module]) {
            for (key, text) in schema.problems(in: table, at: [module]) {
                reader.add(.error, at: [module, key], text)
            }
        }
        guard reader.problems.count == before, case .table(let table) = value else { return nil }
        return table
    }

    /// The settings in `module`'s own `file`, checked against `schema`, or nil and its problems added
    /// to `problems` when it has any.
    private func fileSettings(
        of module: String, schema: ConfigSchema, from file: ModuleFile, problems: inout [ConfigProblem]
    ) -> ConfigTable? {
        let name = Paths.moduleTOMLName(module)
        var reader: TableReader
        do {
            reader = try TableReader(try file.text(named: name), file: name)
        } catch {
            problems.append(error)
            return nil
        }
        let document = reader.document
        if document[ConfigSchema.switchKey] != nil {
            reader.add(.error, at: [ConfigSchema.switchKey], .switchOutsideConfig(module))
        }
        for (key, text) in schema.problems(in: document, at: []) where key != ConfigSchema.switchKey {
            reader.add(.error, at: [key], text)
        }
        problems += reader.problems
        return reader.problems.isEmpty ? document : nil
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
