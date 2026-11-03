/// The settings one module takes in its table in `malum.toml`.
public struct ConfigSchema: Equatable, Sendable {
    /// Each setting's key, with the kind of value it takes.
    public let settings: [String: SettingKind]

    /// Creates a schema from each setting's key and kind.
    public init(_ settings: [String: SettingKind]) {
        self.settings = settings
    }

    /// What's wrong with `table`, keyed by the setting it's about. Empty when the table is fine.
    func problems(in table: ConfigTable, module: String) -> [String: String] {
        var problems: [String: String] = [:]
        for (key, value) in table {
            guard let kind = settings[key] else {
                problems[key] = "unknown setting \(module).\(key)"
                continue
            }
            if !kind.accepts(value) {
                problems[key] = "\(module).\(key) should be \(kind)"
            }
        }
        return problems
    }
}
