/// VSCodium's extensions, listed in `apps/vscodium.toml`: installs every listed one that isn't
/// installed yet, and uninstalls each one Malum manages that isn't listed anymore, through `codium`.
@MainActor
struct VSCodiumExtensions {
    /// Runs `codium`.
    let runner: any CommandRunner
    /// The disk, to find `codium`.
    let files: any FileSystem
    /// Where the record of what Malum installed is kept.
    let state: StateFolder

    /// Installs the extensions in `ids` that aren't installed yet, and uninstalls the ones Malum
    /// manages that aren't in it, reporting each step as it goes. Says whether everything worked.
    func run(_ ids: [String], report: (Message) -> Void) async -> Bool {
        guard let record = InstalledRecord.read(from: state, for: .installExtensions, report: report) else {
            return false
        }
        guard !ids.isEmpty || !record.extensions.isEmpty else { return true }
        guard let sync = sync(report: report) else { return false }
        return await sync.run(listed: ids, managed: record.extensions.sorted(), report: report)
    }

    /// Reports how the extensions `record` holds look now, changing nothing. Says whether it could tell.
    func status(record: InstalledRecord, report: (Message) -> Void) async -> Bool {
        guard !record.extensions.isEmpty else { return true }
        guard let sync = sync(report: report) else { return false }
        let managed = record.extensions.sorted()
        return await sync.status(listed: managed, managed: managed, report: report)
    }

    /// Brings extensions in line through `codium`, or nil, after reporting why, when it isn't installed.
    private func sync(report: (Message) -> Void) -> ManagedSync<Kind>? {
        guard files.item(at: Codium.path) != nil else {
            report(.noCodium)
            return nil
        }
        return ManagedSync(installer: Kind(runner: runner), state: state)
    }

    /// How extensions are installed with `codium`.
    private struct Kind: Installer {
        let runner: any CommandRunner

        var label: MessageText { .vscodiumExtension }

        var plural: MessageText { .vscodiumExtensions }

        func key(of item: String) -> String { item.lowercased() }

        func name(of item: String) -> String { item }

        func installed(report: (Message) -> Void) async -> ((String) -> Bool)? {
            let result = await runner.run(Codium.installed)
            guard result.succeeded else {
                report(.unlistable(.vscodiumExtensions, reason: result.reason))
                return nil
            }
            let ids = Codium.ids(in: result.output)
            return { ids.contains($0.lowercased()) }
        }

        func install(_ item: String) async -> CommandResult {
            await runner.run(Codium.install(item))
        }

        func uninstall(_ item: String) async -> Uninstalled {
            let result = await runner.run(Codium.uninstall(item))
            return result.succeeded ? .done : .failed(reason: result.reason)
        }

        func record(_ item: String, managed: Bool, in record: inout InstalledRecord) {
            record.extensions = record.extensions.filter { $0.lowercased() != item.lowercased() }
            if managed { record.extensions.insert(item) }
        }
    }
}
