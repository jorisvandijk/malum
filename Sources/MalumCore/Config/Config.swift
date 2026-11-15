/// The settings from `malum.toml`, keeping each module's last good table.
///
/// A problem in one module's table affects only that module: it keeps the settings it had, and
/// the other modules take their new ones as normal.
public struct Config: Sendable {
    /// Each module's schema, by the module's id.
    private let schemas: [String: ConfigSchema]
    /// Each module's last good settings, by the module's id, without `enabled`.
    public private(set) var moduleSettings: [String: ModuleSettings] = [:]
    /// The modules whose last good table switches them on.
    public private(set) var enabled: Set<String> = []

    /// Creates a config with no settings yet, for the modules with these schemas.
    public init(schemas: [String: ConfigSchema]) {
        self.schemas = schemas
    }

    /// The ids of the modules this config holds settings for.
    public var modules: Set<String> { Set(schemas.keys) }
    /// Each module's last good table, by the module's id, without `enabled`.
    public var settings: [String: ConfigTable] { moduleSettings.mapValues(\.table) }

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
            let read = settings(of: module, schema: schema, file: file, in: &reader, problems: &fileProblems)
            guard let read else {
                kept.insert(module)
                continue
            }
            take(read, for: module, changed: &changed)
        }
        let loadedFiles = moduleFiles.filter { !kept.contains($0.key) }.map(\.value.path).sorted()
        return ConfigReport(
            loaded: path, moduleFiles: loadedFiles, changed: changed, kept: kept,
            problems: reader.problems + fileProblems)
    }

    /// The settings of `module`, from its table in `malum.toml` that `reader` reads and from its own
    /// `file` when there is one, or nil when either has a problem. The own file's problems go in `problems`.
    private func settings(
        of module: String, schema: ConfigSchema, file: ModuleFile?, in reader: inout TableReader,
        problems: inout [ConfigProblem]
    ) -> ModuleSettings? {
        guard let table = checkedTable(of: module, schema: schema, in: &reader) else { return nil }
        guard let file else { return ModuleSettings(table: table) }
        guard table.keys.allSatisfy({ $0 == ConfigSchema.switchKey }) else {
            reader.add(.error, at: [module], .settingsInTwoPlaces(module))
            return nil
        }
        guard let settings = fileSettings(of: module, schema: schema, from: file, problems: &problems) else {
            return nil
        }
        return ModuleSettings(
            table: table.merging(settings.table) { switchValue, _ in switchValue }, file: settings.file)
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
            schema.settingsCheck?.check(table, at: [module], in: &reader)
        }
        guard reader.problems.count == before, case .table(let table) = value else { return nil }
        return table
    }

    /// The settings in `module`'s own `file`, checked against `schema`, with the text that was checked,
    /// or nil and its problems added to `problems` when it has any.
    private func fileSettings(
        of module: String, schema: ConfigSchema, from file: ModuleFile, problems: inout [ConfigProblem]
    ) -> ModuleSettings? {
        let name = Paths.moduleTOMLName(module)
        let text: String
        var reader: TableReader
        do {
            text = try file.text(named: name)
            reader = try TableReader(text, file: name)
        } catch {
            problems.append(error)
            return nil
        }
        var checked: [ConfigProblem] = []
        var table = reader.document
        if let check = schema.fileCheck {
            checked = check.problems(in: text)
            Self.checkSwitch(in: table, at: [], of: module, in: &reader)
        } else {
            let parts = Self.parts(of: table, schema: schema, in: &reader)
            table = Self.check(parts, of: module, schema: schema, in: &reader)
        }
        problems += reader.problems + checked
        guard reader.problems.isEmpty, checked.isEmpty else { return nil }
        return ModuleSettings(table: table, file: text)
    }

    /// A module's own file, `document`, split by where its settings sit, by path: the tables at the
    /// top, under `[]`, and the plain settings under `[settings]`. A plain setting at the top is an error.
    /// A key `schema` takes as a table stays at the top whatever it holds, so its kind is checked.
    private static func parts(
        of document: ConfigTable, schema: ConfigSchema, in reader: inout TableReader
    ) -> [[String]: ConfigTable] {
        var tables: ConfigTable = [:]
        for (key, value) in document where key != ConfigSchema.settingsTable {
            if Self.isTable(value) || schema.isTable(key) || key == ConfigSchema.switchKey {
                tables[key] = value
            } else {
                reader.add(.error, at: [key], .outsideSettings(key))
            }
        }
        let settings = reader.table(document, ConfigSchema.settingsTable, at: [])
        return [[]: tables, [ConfigSchema.settingsTable]: settings]
    }

    /// Whether `value` is a table or a list of tables.
    private static func isTable(_ value: ConfigValue) -> Bool {
        SettingKind.table.accepts(value) || SettingKind.tables.accepts(value)
    }

    /// Checks each of `parts`, by path, against `module`'s `schema`, and gives them back as one table.
    private static func check(
        _ parts: [[String]: ConfigTable], of module: String, schema: ConfigSchema, in reader: inout TableReader
    ) -> ConfigTable {
        var table: ConfigTable = [:]
        for (path, part) in parts {
            checkSwitch(in: part, at: path, of: module, in: &reader)
            for (key, problem) in schema.problems(in: part, at: path) where key != ConfigSchema.switchKey {
                reader.add(.error, at: path + [key], problem)
            }
            schema.settingsCheck?.check(part, at: path, in: &reader)
            table.merge(part) { first, _ in first }
        }
        return table
    }

    /// Adds an error when `table`, found at `path` in `module`'s own file, holds the switch.
    private static func checkSwitch(
        in table: ConfigTable, at path: [String], of module: String, in reader: inout TableReader
    ) {
        guard table[ConfigSchema.switchKey] != nil else { return }
        reader.add(.error, at: path + [ConfigSchema.switchKey], .switchOutsideConfig(module))
    }

    /// Takes `read` as the settings of `module`, adding it to `changed` when they differ from the
    /// last ones, the checked file's text included, so the module's lines stay right.
    private mutating func take(_ read: ModuleSettings, for module: String, changed: inout Set<String>) {
        var table = read.table
        let switchedOn = table.removeValue(forKey: ConfigSchema.switchKey) == .boolean(true)
        let settings = ModuleSettings(table: table, file: read.file)
        if moduleSettings[module] != settings { changed.insert(module) }
        moduleSettings[module] = settings
        if switchedOn { enabled.insert(module) } else { enabled.remove(module) }
    }
}
