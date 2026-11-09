/// The settings one module takes in its table in `malum.toml`, or in its own file in dots.
public struct ConfigSchema: Equatable, Sendable {
    /// What the module does, in a sentence or two for the docs.
    public let about: String
    /// Each setting, by its key, including `enabled`, which every module takes.
    public let settings: [String: Setting]
    /// How the module's own file is checked, or nil when its keys are checked against `settings`.
    let fileCheck: FileCheck?
    /// What the module checks on top of the kinds of its settings, wherever they are, or nil.
    let settingsCheck: SettingsCheck?

    /// The key that switches a module on or off.
    public static let switchKey = "enabled"
    /// The setting that switches a module on or off. Every module is off until it's set.
    static let switchSetting = Setting(
        .boolean, "Switches the module on. The module stays off until this is set to true.",
        default: .boolean(false))

    /// Creates a schema from what the module does and each of its settings, by key. `enabled` is
    /// added for every module, in place of any setting of that name. With `fileCheck`, the module's
    /// own file is checked that way instead of against `settings`. With `settingsCheck`, settings
    /// whose kinds are right are checked further that way.
    public init(
        about: String, settings: [String: Setting], fileCheck: FileCheck? = nil, settingsCheck: SettingsCheck? = nil
    ) {
        self.about = about
        self.settings = settings.merging([Self.switchKey: Self.switchSetting]) { _, common in common }
        self.fileCheck = fileCheck
        self.settingsCheck = settingsCheck
    }

    /// What's wrong with `table`, found at `path`, keyed by the setting it's about. Empty when the
    /// table is fine. The path is the module's table in `malum.toml`, or empty in the module's own file.
    func problems(in table: ConfigTable, at path: [String]) -> [String: MessageText] {
        var problems: [String: MessageText] = [:]
        for (key, value) in table {
            let name = TableReader.dotted(path + [key])
            guard let setting = settings[key] else {
                problems[key] = .unknownKey(name, isTable: false)
                continue
            }
            if !setting.kind.accepts(value) {
                problems[key] = .shouldBe(name, setting.kind)
            }
        }
        return problems
    }
}
