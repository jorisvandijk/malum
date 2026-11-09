/// What a module checks in its settings on top of their kinds, such as a value from a fixed set or
/// the tables in a list. It runs in both places the settings can be: the module's table in
/// `malum.toml` and its own file.
public enum SettingsCheck: Equatable, Sendable {
    /// The window manager's frame and float rules, read by `WindowManagerConfig`.
    case windowManager

    /// Adds what's wrong with `table`, found at `path`, to `reader`.
    func check(_ table: ConfigTable, at path: [String], in reader: inout TableReader) {
        switch self {
        case .windowManager:
            _ = WindowManagerConfig.read(table) { key, text in
                reader.add(.error, at: path + key, text(TableReader.dotted(path + key)))
            }
        }
    }
}
