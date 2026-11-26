/// The reference of every curated setting `macos.toml` takes, made from `MacOSCatalog` and
/// `PowerSetting.all` so it always matches what Malum reads.
@MainActor
public enum MacOSDocs {
    /// Where the page goes, from the top of the repository.
    public nonisolated static let path = "docs/macos-settings.md"

    /// The start of the page, before the tables.
    private static let header = """
        <!-- Made from MacOSCatalog by `swift run MalumDocs`. Edit the catalog, not this page. -->

        # macOS settings reference

        Every macOS setting `\(Paths.macOSTOMLName)` takes, by table. Each one has a name you can \
        read, and \(Project.name) writes the preferences macOS keeps it in, which it lists under \
        "Writes" for when you want to check one with `defaults read`. A setting that isn't here \
        isn't one \(Project.name) manages yet: it's added to the catalog, not set by its raw name.

        A setting you leave out is left as it is. One \(Project.name) set before and you take out \
        goes back to macOS's own. A name a table doesn't take gets a warning.

        \(Project.name) always turns macOS's own window tiling off, since its window manager tiles: \
        dragging a window to an edge or the top of the screen, or holding Option, doesn't tile it.

        `[\(MacOSSettings.preferencesTable)]` and `[\(MacOSSettings.currentHostTable)]`, which took \
        preferences by the names macOS stores them under, still work for one release, with a \
        warning that names the setting to use instead.

        """

    /// The page.
    public static func page() -> String {
        header + CatalogDocs.sections(of: MacOSCatalog.catalog, place: CatalogDocs.preference) + power
    }

    /// The part of the page about the power settings.
    private static var power: String {
        let sources = Pmset.Source.allCases.map { "`[\(PowerSettings.table).\($0.rawValue)]`" }
        let settings = PowerSetting.all.map { setting in
            let writes = "- Writes: `pmset` `\(setting.pmset)`\n"
            return CatalogDocs.entry(setting.name, setting.about, value: setting.kind.description) + writes
        }
        let about = """
            The power settings, with one table for each power source. Each table takes the same \
            settings. System Settings, Battery, Options.
            """
        return "\n## " + sources.joined(separator: " and ") + "\n\n\(about)\n" + settings.joined()
    }
}
