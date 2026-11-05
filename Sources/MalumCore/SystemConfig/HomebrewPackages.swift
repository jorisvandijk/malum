/// The Homebrew part of system config: installs every listed formula and cask that isn't installed
/// yet, and uninstalls each one Malum manages that isn't listed anymore.
@MainActor
public struct HomebrewPackages {
    /// Runs `brew`.
    private let runner: any CommandRunner
    /// The disk, to find `brew`.
    private let files: any FileSystem
    /// Where the record of what Malum installed is kept.
    private let state: StateFolder

    /// Creates the part, which runs `brew` through `runner`, looks for it on `files` and keeps its
    /// record in `state`.
    public init(runner: any CommandRunner, files: any FileSystem, state: StateFolder) {
        self.runner = runner
        self.files = files
        self.state = state
    }

    /// Installs the packages in `packages` that Homebrew doesn't have yet, and uninstalls the ones
    /// Malum manages that aren't in it, reporting each step as it goes. Says whether everything worked.
    public func run(_ packages: [PackageKind: [String]], report: (Message) -> Void) async -> Bool {
        guard let record = InstalledRecord.read(from: state, for: "install packages", report: report) else {
            return false
        }
        let work = PackageKind.allCases.filter { !(packages[$0] ?? []).isEmpty || !record[$0].isEmpty }
        guard !work.isEmpty else { return true }
        guard files.item(at: Brew.path) != nil else {
            report(Message(.error, "couldn't install packages: Homebrew isn't installed at \(private: Brew.path)"))
            return false
        }
        var succeeded = true
        for kind in work {
            let sync = ManagedSync(installer: Kind(kind: kind, runner: runner), state: state)
            succeeded =
                await sync.run(listed: packages[kind] ?? [], managed: record[kind].sorted(), report: report)
                && succeeded
        }
        return succeeded
    }

    /// How packages of one kind are installed with `brew`.
    private struct Kind: Installer {
        let kind: PackageKind
        let runner: any CommandRunner

        var label: String { kind.label }
        func name(of item: String) -> String { item }

        func installed(report: (Message) -> Void) async -> ((String) -> Bool)? {
            let result = await runner.run(Brew.installed(kind))
            guard result.succeeded else {
                report(Message(.error, "couldn't list the installed \(kind.plural): \(result.reason)"))
                return nil
            }
            let installed = Set(result.output.split(separator: "\n").map(String.init))
            // brew lists a tapped package as `name`, without its `owner/tap/`.
            return { installed.contains($0.split(separator: "/").last.map(String.init) ?? $0) }
        }

        func install(_ item: String) async -> CommandResult {
            await runner.run(Brew.install(item, kind: kind))
        }

        func uninstall(_ item: String) async -> Uninstalled {
            let result = await runner.run(Brew.uninstall(item, kind: kind))
            guard !result.succeeded else { return .done }
            return Brew.isNeeded(result.errors) ? .needed : .failed(reason: result.reason)
        }

        func record(_ item: String, managed: Bool, in record: inout InstalledRecord) {
            if managed { record[kind].insert(item) } else { record[kind].remove(item) }
        }
    }
}
