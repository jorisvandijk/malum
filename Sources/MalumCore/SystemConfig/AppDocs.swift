/// The reference of every app that has a catalog, one page per app, made from its catalog so it
/// always matches what Malum reads.
@MainActor
public enum AppDocs {
    /// The folder the pages go in, from the top of the repository.
    public nonisolated static let folder = "docs/apps"

    /// Each app's page, by its path from the top of the repository.
    public static func pages() -> [String: String] {
        var pages: [String: String] = [:]
        for app in AppConfigs.all {
            guard let catalog = app.catalog else { continue }
            pages["\(folder)/\(app.name).\(Self.pageExtension)"] = page(app, catalog)
        }
        return pages
    }

    /// The extension of a page.
    private static let pageExtension = "md"

    /// The page of `app`, whose catalog is `catalog`.
    static func page(_ app: AppConfig, _ catalog: Catalog) -> String {
        let file = Paths.appFile(named: app.name)
        let header = """
            <!-- Made from the \(app.name) catalog in AppConfigs by `swift run MalumDocs`. Edit the catalog, not this page. -->

            # \(app.name) settings reference

            Every setting `\(file)` takes, by table. Each one has a name you can read, and \
            \(Project.name) writes what \(app.name) keeps it as, which it lists under "Writes". A \
            setting that isn't here isn't one \(Project.name) manages yet: it's added to the \
            catalog, not set by its raw name. A name a table doesn't take gets a warning.

            """
        return header + always(catalog, in: app) + CatalogDocs.sections(of: catalog) { place($0, in: app) }
    }

    /// The part of the page that lists what Malum always writes for `app`, whatever its file says,
    /// or nothing when it writes nothing of its own.
    private static func always(_ catalog: Catalog, in app: AppConfig) -> String {
        guard !catalog.always.isEmpty else { return "" }
        let lines = catalog.always.map { "- \(place($0.target, in: app)): `\($0.value.toml)`\n" }
        return "\n\(Project.name) always writes these, which have no setting:\n\n" + lines.joined()
    }

    /// Where `target` is, as the page names it: a preference by its domain and key, a key in one of
    /// `app`'s files by the file's path and the key.
    private static func place(_ target: CatalogSetting.Target, in app: AppConfig) -> String {
        guard case .file(let path) = target, let table = path.first else { return CatalogDocs.preference(target) }
        let key = path.dropFirst().joined(separator: ".")
        let files = app.files.filter { $0.tables.contains(table) }.map { "`\(CatalogValue.homePrefix)\($0.path)`" }
        return (files + ["`\(key)`"]).joined(separator: " ")
    }
}
