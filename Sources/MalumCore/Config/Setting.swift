/// One setting a module takes in its table in `malum.toml`, with what the docs say about it.
public struct Setting: Equatable, Sendable {
    /// The kind of value it takes.
    public let kind: SettingKind
    /// What the setting does, in a sentence or two for the docs.
    public let about: String
    /// The value the module uses when the setting is left out, or nil when it has none.
    public let defaultValue: ConfigValue?

    /// Creates a setting of `kind`, described by `about`, with the value used when it's left out.
    public init(_ kind: SettingKind, _ about: String, default defaultValue: ConfigValue? = nil) {
        self.kind = kind
        self.about = about
        self.defaultValue = defaultValue
    }
}
