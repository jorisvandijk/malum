/// The settings from `malum.toml`, keeping each module's last good table.
///
/// A problem in one module's table affects only that module: it keeps the settings it had, and
/// the other modules take their new ones as normal.
public struct Config: Sendable {
    /// Each module's schema, by the module's id.
    private let schemas: [String: ConfigSchema]
    /// Each module's last good settings, by the module's id.
    public private(set) var settings: [String: ConfigTable] = [:]

    /// Creates a config with no settings yet, for the modules with these schemas.
    public init(schemas: [String: ConfigSchema]) {
        self.schemas = schemas
    }

    /// The ids of the modules this config holds settings for.
    public var modules: Set<String> { Set(schemas.keys) }

    /// Checks `text`, read from `path`, and takes the settings of every module whose table is fine.
    public mutating func load(_ text: String, from path: String) -> ConfigReport {
        let document: ConfigTable
        do {
            document = ConfigValue.table(try TOMLReader.table(from: text))
        } catch {
            return ConfigReport(loaded: nil, changed: [], kept: modules, problems: [Self.problem(error)])
        }
        let lines = TOMLLines(text)
        var changed: Set<String> = []
        var kept: Set<String> = []
        var problems = strayTables(in: document, lines: lines)
        for (module, schema) in schemas {
            let found = Self.problems(in: document[module], of: module, schema: schema, lines: lines)
            guard found.isEmpty else {
                problems += found
                kept.insert(module)
                continue
            }
            let table = document[module].flatMap(Self.table) ?? [:]
            if settings[module] != table { changed.insert(module) }
            settings[module] = table
        }
        return ConfigReport(loaded: path, changed: changed, kept: kept, problems: problems)
    }

    /// Top-level keys that aren't the table of a known module.
    private func strayTables(in document: ConfigTable, lines: TOMLLines) -> [ConfigProblem] {
        document.keys.filter { schemas[$0] == nil }.map { key in
            let line = lines.line(of: [key])
            guard case .table = document[key] else {
                return ConfigProblem(.warn, line: line, "\(key) isn't inside a module's table")
            }
            return ConfigProblem(.warn, line: line, "unknown module \(key)")
        }
    }

    /// What's wrong with one module's table, each with its line.
    private static func problems(
        in value: ConfigValue?, of module: String, schema: ConfigSchema, lines: TOMLLines
    ) -> [ConfigProblem] {
        guard let value else { return [] }
        guard let table = table(value) else {
            return [ConfigProblem(.error, line: lines.line(of: [module]), "\(module) should be a table")]
        }
        return schema.problems(in: table, module: module).map { key, text in
            ConfigProblem(.error, line: lines.line(of: [module, key]), text)
        }
    }

    /// The table inside `value`, or nil when it isn't one.
    private static func table(_ value: ConfigValue) -> ConfigTable? {
        guard case .table(let table) = value else { return nil }
        return table
    }

    /// A parse error as a problem, at its line and column when the parser gave them.
    private static func problem(_ error: TOMLReadError) -> ConfigProblem {
        switch error {
        case .syntax(let line, let column, let reason):
            ConfigProblem(.error, line: line, column: column, reason)
        case .unreadable(let reason):
            ConfigProblem(.error, "couldn't read \(Paths.configTOMLName): \(reason)")
        }
    }
}
