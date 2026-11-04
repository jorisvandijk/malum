/// The settings one module takes in its table in `malum.toml`.
public struct ConfigSchema: Equatable, Sendable {
    /// What the module does, in a sentence or two for the docs.
    public let about: String
    /// Each setting, by its key.
    public let settings: [String: Setting]

    /// Creates a schema from what the module does and each of its settings, by key.
    public init(about: String, settings: [String: Setting]) {
        self.about = about
        self.settings = settings
    }

    /// What's wrong with `table`, keyed by the setting it's about. Empty when the table is fine.
    func problems(in table: ConfigTable, module: String) -> [String: String] {
        var problems: [String: String] = [:]
        for (key, value) in table {
            guard let setting = settings[key] else {
                problems[key] = "unknown setting \(module).\(key)"
                continue
            }
            if !setting.kind.accepts(value) {
                problems[key] = "\(module).\(key) should be \(setting.kind)"
            }
        }
        return problems
    }
}
