/// What `packages.toml` in dots asks system config to install.
public struct PackageList: Equatable, Sendable {
    /// What reading `packages.toml` gave: the list, or nil when an error stops it, and every problem found.
    public typealias Reading = (list: Self?, problems: [ConfigProblem])

    /// The table that lists Homebrew packages.
    private static let homebrewTable = "homebrew"
    /// The table that lists App Store apps.
    private static let appStoreTable = "app_store"

    /// The Homebrew packages of each kind, by name, in alphabetical order.
    public let homebrew: [PackageKind: [String]]
    /// The App Store apps, in alphabetical order.
    public let appStore: [AppStoreApp]

    /// Creates a list from the Homebrew packages of each kind and the App Store apps.
    public init(homebrew: [PackageKind: [String]] = [:], appStore: [AppStoreApp] = []) {
        self.homebrew = homebrew
        self.appStore = appStore
    }

    /// Reads `text`, the contents of `packages.toml`.
    public static func read(_ text: String) -> Reading {
        let document: ConfigTable
        do {
            document = ConfigValue.table(try TOMLReader.table(from: text))
        } catch {
            return (nil, [problem(error)])
        }
        let lines = TOMLLines(text)
        let known = [homebrewTable, appStoreTable]
        let unknown = document.keys.sorted().filter { !known.contains($0) }.map { key in
            ConfigProblem(.warn, file: Paths.packagesTOMLName, line: lines.line(of: [key]), "unknown table \(key)")
        }
        let (homebrew, homebrewProblems) = homebrewPackages(document[homebrewTable], lines: lines)
        let (appStore, appStoreProblems) = appStoreApps(document[appStoreTable], lines: lines)
        let problems = homebrewProblems + appStoreProblems
        let all = (unknown + problems).sorted { ($0.line ?? Int.max) < ($1.line ?? Int.max) }
        guard problems.isEmpty else { return (nil, all) }
        return (Self(homebrew: homebrew, appStore: appStore), all)
    }

    /// The packages in the `homebrew` table, each written as `name = "formula"` or `name = "cask"`,
    /// and the errors in it.
    private static func homebrewPackages(
        _ value: ConfigValue?, lines: TOMLLines
    ) -> ([PackageKind: [String]], [ConfigProblem]) {
        let (entries, notATable) = entries(of: homebrewTable, in: value, lines: lines)
        var packages: [PackageKind: [String]] = [:]
        var problems = notATable
        for (name, kind) in entries {
            guard case .string(let word) = kind, let kind = PackageKind(rawValue: word) else {
                let text = "\(homebrewTable).\(ConfigValue.key(name)) should be \"formula\" or \"cask\""
                problems.append(problem(text, at: [homebrewTable, name], lines: lines))
                continue
            }
            packages[kind, default: []].append(name)
        }
        return (packages, problems)
    }

    /// The apps in the `app_store` table, each written as `name = id`, and the errors in it.
    private static func appStoreApps(_ value: ConfigValue?, lines: TOMLLines) -> ([AppStoreApp], [ConfigProblem]) {
        let (entries, notATable) = entries(of: appStoreTable, in: value, lines: lines)
        var apps: [AppStoreApp] = []
        var problems = notATable
        for (name, id) in entries {
            guard case .integer(let id) = id, id > 0 else {
                let text = "\(appStoreTable).\(ConfigValue.key(name)) should be the app's App Store ID, a whole number"
                problems.append(problem(text, at: [appStoreTable, name], lines: lines))
                continue
            }
            apps.append(AppStoreApp(name, id: id))
        }
        return (apps, problems)
    }

    /// The entries of the table `name`, sorted by key, or an error when `value` isn't a table.
    private static func entries(
        of name: String, in value: ConfigValue?, lines: TOMLLines
    ) -> ([(key: String, value: ConfigValue)], [ConfigProblem]) {
        guard let value else { return ([], []) }
        guard case .table(let entries) = value else {
            return ([], [problem("\(name) should be a table", at: [name], lines: lines)])
        }
        return (entries.sorted { $0.key < $1.key }, [])
    }

    /// An error at the line of the key `path`.
    private static func problem(_ text: String, at path: [String], lines: TOMLLines) -> ConfigProblem {
        ConfigProblem(.error, file: Paths.packagesTOMLName, line: lines.line(of: path), MessageText(text))
    }

    /// A syntax error as a problem, at its line and column when the parser gave them.
    private static func problem(_ error: TOMLReadError) -> ConfigProblem {
        switch error {
        case .syntax(let line, let column, let reason):
            ConfigProblem(.error, file: Paths.packagesTOMLName, line: line, column: column, MessageText(reason))
        case .unreadable(let reason):
            ConfigProblem(.error, "couldn't read \(Paths.packagesTOMLName): \(reason)")
        }
    }
}
