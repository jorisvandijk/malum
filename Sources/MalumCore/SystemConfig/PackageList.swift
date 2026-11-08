/// What `packages.toml` in dots asks system config to install.
public struct PackageList: Equatable, Sendable {
    /// What reading `packages.toml` gave: the list, or nil when an error stops it, and every problem found.
    public typealias Reading = (list: Self?, problems: [ConfigProblem])

    /// The table that lists Homebrew packages.
    private static let homebrewTable = "homebrew"
    /// The table that lists App Store apps.
    private static let appStoreTable = "app_store"
    /// The table that lists GitHub releases, one table inside it for each.
    static let releaseTable = "release"

    /// The Homebrew packages of each kind, by name, in alphabetical order.
    public let homebrew: [PackageKind: [String]]
    /// The App Store apps, in alphabetical order.
    public let appStore: [AppStoreApp]
    /// The GitHub releases, in alphabetical order.
    public let releases: [ReleaseEntry]

    /// Creates a list from the Homebrew packages of each kind, the App Store apps and the releases.
    public init(homebrew: [PackageKind: [String]] = [:], appStore: [AppStoreApp] = [], releases: [ReleaseEntry] = []) {
        self.homebrew = homebrew
        self.appStore = appStore
        self.releases = releases
    }

    /// Reads `text`, the contents of `packages.toml`.
    public static func read(_ text: String) -> Reading {
        var reader: TableReader
        do {
            reader = try TableReader(text, file: Paths.packagesTOMLName)
        } catch {
            return (nil, [error])
        }
        let document = reader.document
        reader.unknownKeys(document, at: [], known: [homebrewTable, appStoreTable, releaseTable])
        let homebrew = homebrewPackages(reader.table(document, homebrewTable, at: []), reader: &reader)
        let appStore = appStoreApps(reader.table(document, appStoreTable, at: []), reader: &reader)
        let releases = releaseEntries(reader.table(document, releaseTable, at: []), reader: &reader)
        let problems = reader.problemsByLine
        guard !reader.hasErrors else { return (nil, problems) }
        return (Self(homebrew: homebrew, appStore: appStore, releases: releases), problems)
    }

    /// The packages in the `homebrew` table, each written as `name = "formula"` or `name = "cask"`.
    private static func homebrewPackages(_ table: ConfigTable, reader: inout TableReader) -> [PackageKind: [String]] {
        var packages: [PackageKind: [String]] = [:]
        for (name, kind) in table.sorted(by: { $0.key < $1.key }) {
            guard !name.hasPrefix("-") else {
                reader.add(
                    .error, at: [homebrewTable, name], .notPackageName(TableReader.dotted([homebrewTable, name])))
                continue
            }
            guard case .string(let word) = kind, let kind = PackageKind(rawValue: word) else {
                reader.expect([homebrewTable, name], MessageText.homebrewKind)
                continue
            }
            packages[kind, default: []].append(name)
        }
        return packages
    }

    /// The apps in the `app_store` table, each written as `name = id`.
    private static func appStoreApps(_ table: ConfigTable, reader: inout TableReader) -> [AppStoreApp] {
        table.sorted { $0.key < $1.key }.compactMap { name, id in
            guard case .integer(let id) = id, id > 0 else {
                reader.expect([appStoreTable, name], MessageText.appStoreID)
                return nil
            }
            return AppStoreApp(name, id: id)
        }
    }

    /// The releases in the `release` table, each a table with `repo` and maybe `asset`.
    private static func releaseEntries(_ table: ConfigTable, reader: inout TableReader) -> [ReleaseEntry] {
        table.sorted { $0.key < $1.key }.compactMap { name, value in
            let path = [releaseTable, name]
            guard let fields = reader.table(value, at: path) else { return nil }
            guard Paths.isPlainName(name) else {
                reader.add(.error, at: path, .notPlainName(TableReader.dotted(path)))
                return nil
            }
            reader.unknownKeys(fields, at: path, known: ["repo", "asset"])
            guard case .string(let repo) = fields["repo"], isRepository(repo) else {
                reader.expect(path + ["repo"], MessageText.repository)
                return nil
            }
            switch fields["asset"] {
            case nil:
                return ReleaseEntry(name, repo: repo)
            case .string(let asset):
                return ReleaseEntry(name, repo: repo, asset: asset)
            default:
                reader.expect(path + ["asset"], SettingKind.string)
                return nil
            }
        }
    }

    /// Whether `text` names a repository as `owner/name`.
    private static func isRepository(_ text: String) -> Bool {
        let parts = text.split(separator: "/", omittingEmptySubsequences: false)
        return parts.count == ["owner", "name"].count && parts.allSatisfy { !$0.isEmpty && !$0.hasPrefix(".") }
    }
}
