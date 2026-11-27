/// Every table `keyboard.toml` takes: the hyper key, the key remaps and the shortcuts. Malum acts
/// on them itself, so they write the tables `KeyboardConfig` reads.
enum KeyboardCatalog {
    /// The table that holds the hyper key.
    static let hyperTable = "hyper"
    /// The key in `[hyper]` that names it.
    static let hyperKey = "key"
    /// The table of key remaps.
    static let remapsTable = "remaps"
    /// The table of shortcuts.
    static let shortcutsTable = "shortcuts"

    /// The catalog of `keyboard.toml`.
    static let catalog = Catalog(
        file: Paths.moduleTOMLName(KeyboardConfig.module),
        tables: [
            CatalogTable(
                name: hyperTable,
                about: "The hyper key holds ctrl, option, cmd and shift down together while you hold it, so a "
                    + "shortcut such as hyper+k works in any app that lets you set one.",
                settings: [
                    CatalogSetting(
                        hyperKey, "The key that becomes the hyper key. Leave it out for no hyper key.",
                        .choice(Key.hyperKeys.map { .word($0.name, .string($0.name)) }), [.own(hyperTable, hyperKey)])
                ]),
            CatalogTable(
                name: remapsTable,
                about: "Keys that type as another key, on every keyboard, while \(Project.name) runs. The hyper key "
                    + "can't be remapped.",
                data: CatalogData(
                    keys: "the key pressed, by its name, such as \"caps_lock\"",
                    values: "the key it types as, by its name, such as \"escape\"", into: [remapsTable])),
            CatalogTable(
                name: shortcutsTable, about: "Shortcuts and what they do.",
                data: CatalogData(
                    keys: "a shortcut: modifiers `ctrl`, `option`, `cmd`, `shift` or `hyper` for all four, then a "
                        + "key name, joined by `+`, such as \"hyper+b\" or \"ctrl+cmd+h\"",
                    values: "what it does: an app's bundle ID, which the window manager runs or raises, or an "
                        + "action a module offers, such as \"launcher\"",
                    into: [shortcutsTable])),
        ])
}
