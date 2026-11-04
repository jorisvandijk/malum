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

    /// Installs the packages in `packages` that Homebrew doesn't have yet, reporting each step as it
    /// goes. Says whether everything listed is installed now.
    public func run(_ packages: [PackageKind: [String]], report: (Message) -> Void) async -> Bool {
        let wanted = PackageKind.allCases.map { kind in (kind, packages[kind] ?? []) }.filter { !$0.1.isEmpty }
        guard !wanted.isEmpty else { return true }
        guard files.item(at: Brew.path) != nil else {
            report(Message(.error, "couldn't install packages: Homebrew isn't installed at \(private: Brew.path)"))
            return false
        }
        var succeeded = true
        for (kind, names) in wanted {
            succeeded = await install(names, kind: kind, report: report) && succeeded
        }
        return succeeded
    }

    /// Installs the packages of `kind` among `names` that Homebrew doesn't have yet.
    private func install(_ names: [String], kind: PackageKind, report: (Message) -> Void) async -> Bool {
        let listed = await runner.run(Brew.installed(kind))
        guard listed.succeeded else {
            report(Message(.error, "couldn't list the installed \(kind.plural): \(listed.reason)"))
            return false
        }
        let installed = Set(listed.output.split(separator: "\n").map(String.init))
        let missing = names.filter { !installed.contains(Self.shortName($0)) }
        guard !missing.isEmpty else {
            report(Message(.info, "every listed \(kind.label) is installed"))
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
            report(Message(.error, "couldn't install \(kind.label) \(name): it isn't a package name"))
            return false
        }
        report(Message(.info, "installing \(kind.label) \(name)"))
        let result = await runner.run(Brew.install(name, kind: kind))
        guard result.succeeded else {
            report(Message(.error, "couldn't install \(kind.label) \(name): \(result.reason)"))
            return false
        }
        report(Message(.info, "installed \(kind.label) \(name)"))
        return true
    }

    /// The name `brew list` shows for `name`: without the tap, when it's written as `owner/tap/name`.
    private static func shortName(_ name: String) -> String {
        name.split(separator: "/").last.map(String.init) ?? name
    }
}
