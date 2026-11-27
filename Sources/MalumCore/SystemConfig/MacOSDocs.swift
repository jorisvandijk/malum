/// The reference of every curated setting `macos.toml` takes, made from `MacOSCatalog` so it always
/// matches what Malum reads.
@MainActor
public enum MacOSDocs {
    /// Where the page goes, from the top of the repository.
    public nonisolated static let path = "docs/macos-settings.md"

    /// The start of the page, before the tables.
    private static let header = """
        <!-- Made from MacOSCatalog by `swift run MalumDocs`. Edit the catalog, not this page. -->

        # macOS settings reference

        Every macOS setting `\(Paths.macOSTOMLName)` takes, by table. Each one has a name you can \
        read. For one macOS keeps as a preference, \(Project.name) writes the preferences and lists \
        them under "Writes", for when you want to check one with `defaults read`; a power setting \
        lists the name `pmset` gives it. A setting that isn't here isn't one \(Project.name) \
        manages yet: it's added to the catalog, not set by its raw name.

        A setting you leave out is left as it is. One \(Project.name) set before and you take out \
        goes back to macOS's own. A name a table doesn't take gets a warning.

        \(Project.name) always turns macOS's own window tiling off, since its window manager tiles: \
        dragging a window to an edge or the top of the screen, or holding Option, doesn't tile it.

        """

    /// The page.
    public static func page() -> String {
        header + CatalogDocs.sections(of: MacOSCatalog.catalog, place: place)
    }

    /// What a setting writes, as the page names it: a preference by its domain and key, a power
    /// setting by the name `pmset` gives it, and nothing for the rest, which Malum acts on itself.
    private static func place(_ target: CatalogSetting.Target) -> String {
        guard case .file(let path) = target else { return CatalogDocs.preference(target) }
        guard path.first == PowerSettings.table, let name = path.last else { return "" }
        return "`pmset` `\(name)`"
    }
}
