/// Every curated setting `macos.toml` takes, by table, such as `natural_scrolling` in `[pointer]`.
/// Each one says which macOS preferences it writes, so a person never needs the names macOS
/// stores them under. A setting macOS has that isn't here is added here, not set by its raw name.
enum MacOSCatalog {
    /// The catalog of `macos.toml`.
    static let catalog = Catalog(
        file: Paths.macOSTOMLName, tables: tables, always: alwaysSet, alwaysConflict: MessageText.tilingAlwaysOff)

    /// Every curated table, in the order the docs show them.
    static let tables: [CatalogTable] = [
        appearance, menuBar, clock, sound, pointer, trackpad, keyboard, text, finder, desktop, dock, screenCapture,
        siri, gameCenter,
    ]

    /// The preferences Malum always sets, whatever `macos.toml` says: macOS's own window tiling is
    /// off, since Malum's window manager does that.
    static let alwaysSet: [Catalog.Always] = [
        Catalog.Always(target: .domain(windowManager, "EnableTilingByEdgeDrag"), value: .boolean(false)),
        Catalog.Always(target: .domain(windowManager, "EnableTopTilingByEdgeDrag"), value: .boolean(false)),
        Catalog.Always(target: .domain(windowManager, "EnableTilingOptionAccelerator"), value: .boolean(false)),
    ]

    /// The domain of the desktop, Stage Manager and window tiling.
    static let windowManager = "com.apple.WindowManager"

    /// The curated setting that writes the preference `key` in `domain`, as `table.name`, or nil
    /// when none does.
    static func setting(writing key: String, in domain: String) -> String? {
        catalog.setting(writing: .domain(domain, key))
    }
}
