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
        let record: InstalledRecord
        do {
            record = try InstalledRecord.read(from: state)
        } catch {
            report(Message(.error, "couldn't install packages: \(MessageText(error: error))"))
            return false
        }
        let work = PackageKind.allCases.map { kind in
            let listed = packages[kind] ?? []
            return (kind, listed, record[kind].subtracting(listed).sorted())
        }.filter { !$0.1.isEmpty || !$0.2.isEmpty }
        guard !work.isEmpty else { return true }
        guard files.item(at: Brew.path) != nil else {
            report(Message(.error, "couldn't install packages: Homebrew isn't installed at \(private: Brew.path)"))
            return false
        }
        var succeeded = true
        for (kind, listed, unlisted) in work {
            succeeded =
                await sync(kind, listed: listed, unlisted: unlisted, managed: record[kind], report: report)
                && succeeded
        }
        return succeeded
    }

    /// Installs the packages of `kind` among `listed` that Homebrew doesn't have yet, takes over the
    /// ones it has that Malum doesn't manage yet, and uninstalls `unlisted`.
    private func sync(
        _ kind: PackageKind, listed: [String], unlisted: [String], managed: Set<String>, report: (Message) -> Void
    ) async -> Bool {
        let result = await runner.run(Brew.installed(kind))
        guard result.succeeded else {
            report(Message(.error, "couldn't list the installed \(kind.plural): \(result.reason)"))
            return false
        }
        let installed = Set(result.output.split(separator: "\n").map(String.init))
        let isInstalled = { (name: String) in installed.contains(Self.shortName(name)) }
        var succeeded = adopt(listed.filter { isInstalled($0) && !managed.contains($0) }, kind: kind, report: report)
        let missing = listed.filter { !isInstalled($0) }
        if missing.isEmpty && !listed.isEmpty { report(Message(.info, "every listed \(kind.label) is installed")) }
        for name in missing {
            succeeded = await install(name, kind: kind, report: report) && succeeded
        }
        for name in unlisted {
            succeeded = await uninstall(name, kind: kind, installed: isInstalled(name), report: report) && succeeded
        }
        return succeeded
    }

    /// Records `names` as managed by Malum, since they were installed already.
    private func adopt(_ names: [String], kind: PackageKind, report: (Message) -> Void) -> Bool {
        guard !names.isEmpty else { return true }
        guard remember(kind, report: report, { $0.formUnion(names) }) else { return false }
        for name in names {
            report(Message(.info, "\(kind.label) \(name) was already installed, \(Project.name) manages it now"))
        }
        return true
    }

    /// Installs one package and records it. Says whether it worked.
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
        return remember(kind, report: report) { $0.insert(name) }
    }

    /// Uninstalls one package Malum manages, when it's still `installed`, and takes it out of the
    /// record. Says whether it worked.
    private func uninstall(
        _ name: String, kind: PackageKind, installed: Bool, report: (Message) -> Void
    ) async -> Bool {
        guard installed else {
            report(Message(.info, "\(kind.label) \(name) was already uninstalled"))
            return remember(kind, report: report) { $0.remove(name) }
        }
        report(Message(.info, "uninstalling \(kind.label) \(name)"))
        let result = await runner.run(Brew.uninstall(name, kind: kind))
        switch (result.succeeded, Brew.isNeeded(result.errors)) {
        case (true, _):
            report(Message(.info, "uninstalled \(kind.label) \(name)"))
        case (false, true):
            report(
                Message(
                    .warn,
                    "\(kind.label) \(name) is still needed by other packages, so it stays and \(Project.name) no longer manages it"
                ))
        case (false, false):
            report(Message(.error, "couldn't uninstall \(kind.label) \(name): \(result.reason)"))
            return false
        }
        return remember(kind, report: report) { $0.remove(name) }
    }

    /// Makes `change` to the packages of `kind` in the record. Says whether it worked.
    private func remember(
        _ kind: PackageKind, report: (Message) -> Void, _ change: (inout Set<String>) -> Void
    ) -> Bool {
        do {
            try InstalledRecord.change(in: state) { change(&$0[kind]) }
            return true
        } catch {
            report(Message(.error, "couldn't record what \(Project.name) installed: \(MessageText(error: error))"))
            return false
        }
    }

    /// The name `brew list` shows for `name`: without the tap, when it's written as `owner/tap/name`.
    private static func shortName(_ name: String) -> String {
        name.split(separator: "/").last.map(String.init) ?? name
    }
}
