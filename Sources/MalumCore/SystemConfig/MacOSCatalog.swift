/// Every curated setting `macos.toml` takes, by table, such as `natural_scrolling` in `[pointer]`.
/// Each one says which macOS preferences it writes, so a person never needs the names macOS
/// stores them under. A setting macOS has that isn't here is added here, not set by its raw name.
enum MacOSCatalog {
    /// Every curated table, in the order the docs show them.
    static let tables: [MacOSTable] = [
        appearance, menuBar, clock, sound, pointer, trackpad, keyboard, text, finder, desktop, dock, screenCapture,
        siri, gameCenter,
    ]

    /// The preferences Malum always sets, whatever `macos.toml` says: macOS's own window tiling is
    /// off, since Malum's window manager does that.
    static let alwaysSet: [(target: MacOSSetting.Target, value: ConfigValue)] = [
        (.domain(windowManager, "EnableTilingByEdgeDrag"), .boolean(false)),
        (.domain(windowManager, "EnableTopTilingByEdgeDrag"), .boolean(false)),
        (.domain(windowManager, "EnableTilingOptionAccelerator"), .boolean(false)),
    ]

    /// The domain of the desktop, Stage Manager and window tiling.
    static let windowManager = "com.apple.WindowManager"

    /// The curated setting that writes the preference `key` in `domain`, as `table.name`, or nil
    /// when none does.
    static func setting(writing key: String, in domain: String) -> String? {
        let target = MacOSSetting.Target(domain: domain, key: key)
        for table in tables {
            guard let setting = table.settings.first(where: { $0.targets.contains(target) }) else { continue }
            return TableReader.dotted([table.name, setting.name])
        }
        return nil
    }
}

/// One curated table in `macos.toml`, such as `[trackpad]`, and the settings it takes.
struct MacOSTable: Sendable {
    /// The table's name.
    let name: String
    /// What the table is about, in a sentence for the docs.
    let about: String
    /// Its settings, in the order the docs show them.
    let settings: [MacOSSetting]
}
