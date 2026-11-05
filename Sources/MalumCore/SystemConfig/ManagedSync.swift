/// Brings one kind of thing in line with its list: takes over what's listed and already
/// installed, installs what's missing, and uninstalls what Malum manages that isn't listed
/// anymore. Every installer shares it, so each kind only says how to list, install and uninstall.
@MainActor
struct ManagedSync<Kind: Installer> {
    /// How to install this kind.
    let installer: Kind
    /// Where the record of what Malum manages is kept.
    let state: StateFolder

    /// Brings `listed` in line, where `managed` is what the record holds, reporting each step.
    /// Says whether everything worked.
    func run(listed: [Kind.Item], managed: [Kind.Item], report: (Message) -> Void) async -> Bool {
        let managedKeys = Set(managed.map(installer.key))
        let listedKeys = Set(listed.map(installer.key))
        let unlisted = managed.filter { !listedKeys.contains(installer.key(of: $0)) }
        guard !listed.isEmpty || !unlisted.isEmpty else { return true }
        guard let isInstalled = await installer.installed(report: report) else { return false }
        let adopted = listed.filter { isInstalled($0) && !managedKeys.contains(installer.key(of: $0)) }
        var succeeded = adopt(adopted, report: report)
        let missing = listed.filter { !isInstalled($0) }
        if missing.isEmpty && !listed.isEmpty { report(.allInstalled(installer.label)) }
        let removing = unlisted.filter(isInstalled)
        if !missing.isEmpty || !removing.isEmpty {
            let ready = await installer.prepare(
                installing: !missing.isEmpty, removing: !removing.isEmpty, report: report)
            guard ready else { return false }
        }
        for item in missing {
            succeeded = await install(item, report: report) && succeeded
        }
        for item in unlisted {
            succeeded = await uninstall(item, installed: isInstalled(item), report: report) && succeeded
        }
        return succeeded
    }

    /// Records `items` as managed, since they were installed already. Says whether it worked.
    private func adopt(_ items: [Kind.Item], report: (Message) -> Void) -> Bool {
        guard !items.isEmpty else { return true }
        guard remember(items, managed: true, report: report) else { return false }
        for item in items { report(.adopted(installer.label, installer.name(of: item))) }
        return true
    }

    /// Installs one item and records it. Says whether it worked.
    private func install(_ item: Kind.Item, report: (Message) -> Void) async -> Bool {
        let name = installer.name(of: item)
        report(.installing(installer.label, installer.shown(item)))
        let result = await installer.install(item)
        guard result.succeeded else {
            report(.installFailed(installer.label, name, reason: result.reason))
            return false
        }
        report(.installed(installer.label, name))
        return remember([item], managed: true, report: report)
    }

    /// Uninstalls one item Malum manages, when it's still `installed`, and takes it out of the
    /// record. Says whether it worked.
    private func uninstall(_ item: Kind.Item, installed: Bool, report: (Message) -> Void) async -> Bool {
        let name = installer.name(of: item)
        guard installed else {
            report(.alreadyUninstalled(installer.label, name))
            return remember([item], managed: false, report: report)
        }
        report(.uninstalling(installer.label, installer.shown(item)))
        switch await installer.uninstall(item) {
        case .done:
            report(.uninstalled(installer.label, name))
        case .needed:
            report(.stillNeeded(installer.label, name))
        case .failed(let reason):
            report(.uninstallFailed(installer.label, name, reason: reason))
            return false
        }
        return remember([item], managed: false, report: report)
    }

    /// Adds `items` to the record, or takes them out when they're no longer `managed`.
    private func remember(_ items: [Kind.Item], managed: Bool, report: (Message) -> Void) -> Bool {
        InstalledRecord.remember(in: state, report: report) { record in
            for item in items { installer.record(item, managed: managed, in: &record) }
        }
    }
}
