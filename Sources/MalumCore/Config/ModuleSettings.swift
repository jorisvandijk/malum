/// One module's checked settings: its table, and the text of its own file in dots when the settings
/// are there, such as `keyboard.toml`, so the module can find lines without reading the file again.
public struct ModuleSettings: Equatable, Sendable {
    /// The settings, without `enabled`.
    public let table: ConfigTable
    /// The text of the module's own file as it was checked, or nil when the settings are in `malum.toml`.
    public let file: String?

    /// Creates settings from `table` and the checked text of the module's own `file`.
    public init(table: ConfigTable = [:], file: String? = nil) {
        self.table = table
        self.file = file
    }
}
