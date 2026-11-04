/// The Homebrew part of system config: installs every listed formula and cask that isn't installed yet.
@MainActor
public struct HomebrewPackages {
    /// Runs `brew`.
    private let runner: any CommandRunner
    /// The disk, to find `brew`.
    private let files: any FileSystem

    /// Creates the part, which runs `brew` through `runner` and looks for it on `files`.
    public init(runner: any CommandRunner, files: any FileSystem) {
        self.runner = runner
        self.files = files
    }

    /// Installs what system config's `settings` list and Homebrew doesn't have yet, reporting each
    /// step as it goes. Says whether everything listed is installed now.
    public func run(_ settings: ConfigTable, report: (Message) -> Void) async -> Bool {
        let wanted = PackageKind.allCases.map { kind in (kind, Self.names(settings[kind.setting])) }
        guard wanted.contains(where: { !$0.1.isEmpty }) else { return true }
        guard files.item(at: Brew.path) != nil else {
            report(Message(.error, "couldn't install packages: Homebrew isn't installed at \(private: Brew.path)"))
            return false
        }
        var succeeded = true
        for (kind, names) in wanted where !names.isEmpty {
            succeeded = await install(names, kind: kind, report: report) && succeeded
        }
        return succeeded
    }

    /// Installs the packages of `kind` among `names` that Homebrew doesn't have yet.
    private func install(_ names: [String], kind: PackageKind, report: (Message) -> Void) async -> Bool {
        let listed = await runner.run(Brew.installed(kind))
        guard listed.succeeded else {
            report(Message(.error, "couldn't list the installed \(kind.setting): \(listed.reason)"))
            return false
        }
        let installed = Set(listed.output.split(separator: "\n").map(String.init))
        let missing = names.filter { !installed.contains(Self.shortName($0)) }
        guard !missing.isEmpty else {
            report(Message(.info, "every listed \(kind.rawValue) is installed"))
            return true
        }
        var succeeded = true
        for name in missing {
            succeeded = await install(name, kind: kind, report: report) && succeeded
        }
        return succeeded
    }

    /// Installs one package, and says whether it worked.
    private func install(_ name: String, kind: PackageKind, report: (Message) -> Void) async -> Bool {
        guard !name.hasPrefix("-") else {
            report(Message(.error, "couldn't install \(kind.rawValue) \(name): it isn't a package name"))
            return false
        }
        report(Message(.info, "installing \(kind.rawValue) \(name)"))
        let result = await runner.run(Brew.install(name, kind: kind))
        guard result.succeeded else {
            report(Message(.error, "couldn't install \(kind.rawValue) \(name): \(result.reason)"))
            return false
        }
        report(Message(.info, "installed \(kind.rawValue) \(name)"))
        return true
    }

    /// The names a setting lists, each once, in the order given. The schema has checked that it's a
    /// list of text, so anything else is never there.
    private static func names(_ value: ConfigValue?) -> [String] {
        guard case .array(let items) = value else { return [] }
        var seen: Set<String> = []
        return items.compactMap { item in
            guard case .string(let name) = item, seen.insert(name).inserted else { return nil }
            return name
        }
    }

    /// The name `brew list` shows for `name`: without the tap, when it's written as `owner/tap/name`.
    private static func shortName(_ name: String) -> String {
        name.split(separator: "/").last.map(String.init) ?? name
    }
}
