/// Reads `webapps.toml` in dots: one table per web app, named by the app, with its `url` and maybe
/// an `icon`.
public enum WebAppList {
    /// What reading `webapps.toml` gave: the apps, or nil when an error stops it, and every problem.
    public typealias Reading = (apps: [WebApp]?, problems: [ConfigProblem])

    /// A web app's site.
    private static let urlKey = "url"
    /// A web app's icon.
    private static let iconKey = "icon"
    /// The icon files Malum turns into the app's icon.
    private static let iconExtensions = [".png", ".\(WebApp.iconExtension)"]

    /// Reads `text`, the contents of `webapps.toml`. The apps come in alphabetical order.
    public static func read(_ text: String) -> Reading {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.webAppsTOMLName)
        } catch {
            return (nil, [error])
        }
        let apps = reader.document.sorted { $0.key < $1.key }.compactMap { name, value in
            app(name, value, reader: &reader)
        }
        let problems = reader.problemsByLine
        guard !reader.hasErrors else { return (nil, problems) }
        return (apps, problems)
    }

    /// The app named `name` in the table `value`, or nil when it has a problem.
    private static func app(_ name: String, _ value: ConfigValue, reader: inout TableReader) -> WebApp? {
        let path = [name]
        guard let fields = reader.table(value, at: path) else { return nil }
        guard Paths.isPlainName(name) else {
            reader.add(.error, at: path, .notPlainName(name))
            return nil
        }
        reader.unknownKeys(fields, at: path, known: [urlKey, iconKey])
        let app = WebApp(name: name, url: "", icon: nil)
        guard app.bundleID != WebApp.bundleIDPrefix else {
            reader.add(.error, at: path, .noBundleIDLetters(name))
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
