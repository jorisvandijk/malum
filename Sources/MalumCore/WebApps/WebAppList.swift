/// Reads `webapps.toml` in dots: one table per web app in `[apps]`, named by the app, with its
/// `url` and maybe an `icon`.
public enum WebAppList {
    /// What reading `webapps.toml` gave: the apps, or nil when an error stops it, and every problem.
    public typealias Reading = (apps: [WebApp]?, problems: [ConfigProblem])

    /// The table of web apps, by name.
    static let appsTable = "apps"
    /// A web app's site.
    static let urlKey = "url"
    /// A web app's icon.
    static let iconKey = "icon"
    /// The icon files Malum turns into the app's icon.
    private static let iconExtensions = [".png", ".\(WebApp.iconExtension)"]

    /// The catalog of `webapps.toml`.
    static let catalog = Catalog(
        file: Paths.webAppsTOMLName,
        tables: [
            CatalogTable(
                name: appsTable,
                about: "Sites that get an app of their own, in the Applications folder in your home folder.",
                entries: CatalogEntries(
                    keys: "the app's name, such as \"Frigate\", which names `Frigate.app`",
                    settings: [
                        CatalogSetting(
                            urlKey, "The site, `http` or `https`.", .text(.plain),
                            [.own(appsTable, CatalogEntries.entry, urlKey)]),
                        CatalogSetting(
                            iconKey,
                            "A square `.png` or an `.icns` file, as a path inside dots, such as "
                                + "\"icons/frigate.png\". Left out, the app gets the plain app icon.",
                            .text(.plain), [.own(appsTable, CatalogEntries.entry, iconKey)]),
                    ], optional: [iconKey]))
        ])

    /// Reads `text`, the contents of `webapps.toml`, through `catalog`. The apps come in
    /// alphabetical order.
    public static func read(_ text: String) -> Reading {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.webAppsTOMLName)
        } catch {
            return (nil, [error])
        }
        reader.unknownKeys(reader.document, at: [], known: catalog.topTables)
        let own = catalog.own(&reader, home: "")
        let apps = reader.table(own, appsTable, at: []).sorted { $0.key < $1.key }.compactMap { name, value in
            app(name, value, reader: &reader)
        }
        let problems = reader.problemsByLine
        guard !reader.hasErrors else { return (nil, problems) }
        return (apps, problems)
    }

    /// The app named `name` in the table `value`, which the catalog read, or nil when it has a problem.
    private static func app(_ name: String, _ value: ConfigValue, reader: inout TableReader) -> WebApp? {
        let path = [appsTable, name]
        // The catalog reported a table or a `url` that's missing.
        guard case .table(let fields) = value, fields[urlKey] != nil else { return nil }
        guard Paths.isPlainName(name) else {
            reader.add(.error, at: path, .notPlainName(TableReader.dotted(path)))
            return nil
        }
        let app = WebApp(name: name, url: "", icon: nil)
        guard app.bundleID != WebApp.bundleIDPrefix else {
            reader.add(.error, at: path, .noBundleIDLetters(TableReader.dotted(path)))
            return nil
        }
        guard case .string(let url) = fields[urlKey], WebAddress.url(url) != nil else {
            reader.expect(path + [urlKey], MessageText.webAddress)
            return nil
        }
        switch fields[iconKey] {
        case nil:
            return WebApp(name: name, url: url, icon: nil)
        case .string(let icon) where isIconFile(icon):
            return WebApp(name: name, url: url, icon: icon)
        default:
            reader.expect(path + [iconKey], MessageText.iconFile)
            return nil
        }
    }

    /// Whether `path` is a PNG or ICNS file inside dots: relative, never climbing out.
    private static func isIconFile(_ path: String) -> Bool {
        let lowered = path.lowercased()
        let parts = path.split(separator: "/")
        return !path.hasPrefix("/") && !parts.contains("..") && iconExtensions.contains(where: lowered.hasSuffix)
    }
}
