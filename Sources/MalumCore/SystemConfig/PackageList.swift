/// What `packages.toml` in dots asks system config to install.
public struct PackageList: Equatable, Sendable {
    /// What reading `packages.toml` gave: the list, or nil when an error stops it, and every problem found.
    public typealias Reading = (list: Self?, problems: [ConfigProblem])

    /// The table that lists Homebrew packages.
    private static let homebrewTable = "homebrew"

    /// The Homebrew packages of each kind, by name, in alphabetical order.
    public let homebrew: [PackageKind: [String]]

    /// Creates a list from the Homebrew packages of each kind.
    public init(homebrew: [PackageKind: [String]] = [:]) {
        self.homebrew = homebrew
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
        let unknown = document.keys.sorted().filter { $0 != homebrewTable }.map { key in
            ConfigProblem(.warn, file: Paths.packagesTOMLName, line: lines.line(of: [key]), "unknown table \(key)")
        }
        let (homebrew, problems) = homebrewPackages(document[homebrewTable], lines: lines)
        let all = (unknown + problems).sorted { ($0.line ?? Int.max) < ($1.line ?? Int.max) }
        guard problems.isEmpty else { return (nil, all) }
        return (Self(homebrew: homebrew), all)
    }

    /// The packages in the `homebrew` table, each written as `name = "formula"` or `name = "cask"`,
    /// and the errors in it.
    private static func homebrewPackages(
        _ value: ConfigValue?, lines: TOMLLines
    ) -> ([PackageKind: [String]], [ConfigProblem]) {
        guard let value else { return ([:], []) }
        guard case .table(let entries) = value else {
            let line = lines.line(of: [homebrewTable])
            return (
                [:], [ConfigProblem(.error, file: Paths.packagesTOMLName, line: line, "homebrew should be a table")]
            )
        }
        var packages: [PackageKind: [String]] = [:]
        var problems: [ConfigProblem] = []
        for (name, kind) in entries.sorted(by: { $0.key < $1.key }) {
            guard case .string(let word) = kind, let kind = PackageKind(rawValue: word) else {
                let text = "\(homebrewTable).\(ConfigValue.key(name)) should be \"formula\" or \"cask\""
                let line = lines.line(of: [homebrewTable, name])
                problems.append(ConfigProblem(.error, file: Paths.packagesTOMLName, line: line, MessageText(text)))
                continue
            }
            packages[kind, default: []].append(name)
        }
        return (packages, problems)
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
