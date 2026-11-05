/// The App Store part of system config: installs every listed app that isn't installed yet, and
/// uninstalls each one Malum manages that isn't listed anymore, through `mas`.
@MainActor
public struct AppStoreApps {
    /// Runs `mas`.
    private let runner: any CommandRunner
    /// The disk, to find `mas`.
    private let files: any FileSystem
    /// The run's sudo, since mas installs and uninstalls as root.
    private let sudo: SudoSession
    /// Where the record of what Malum installed is kept.
    private let state: StateFolder

    /// Creates the part, which runs `mas` through `runner`, looks for it on `files`, gets root from
    /// `sudo` and keeps its record in `state`.
    public init(runner: any CommandRunner, files: any FileSystem, sudo: SudoSession, state: StateFolder) {
        self.runner = runner
        self.files = files
        self.sudo = sudo
        self.state = state
    }

    /// Installs the apps in `apps` that aren't installed yet, and uninstalls the ones Malum manages
    /// that aren't in it, reporting each step as it goes. Says whether everything worked.
    public func run(_ apps: [AppStoreApp], report: (Message) -> Void) async -> Bool {
        let record: InstalledRecord
        do {
            record = try InstalledRecord.read(from: state)
        } catch {
            report(Message(.error, "couldn't install App Store apps: \(MessageText(error: error))"))
            return false
        }
        let listed = Set(apps.map(\.id))
        let unlisted = record.appStore.sorted { $0.key < $1.key }.filter { !listed.contains($0.value) }.map {
            AppStoreApp($0.key, id: $0.value)
        }
        guard !apps.isEmpty || !unlisted.isEmpty, let installed = await installedIDs(report: report) else {
            return apps.isEmpty && unlisted.isEmpty
        }
        let managed = Set(record.appStore.values)
        var succeeded = adopt(apps.filter { installed.contains($0.id) && !managed.contains($0.id) }, report: report)
        for app in unlisted where !installed.contains(app.id) {
            report(Message(.info, "App Store app \(app.name) was already uninstalled"))
            succeeded = remember(report: report) { $0.appStore[app.name] = nil } && succeeded
        }
        let missing = apps.filter { !installed.contains($0.id) }
        let removing = unlisted.filter { installed.contains($0.id) }
        if missing.isEmpty && !apps.isEmpty { report(Message(.info, "every listed App Store app is installed")) }
        guard !missing.isEmpty || !removing.isEmpty else { return succeeded }
        let reason = Self.reason(installing: !missing.isEmpty, removing: !removing.isEmpty)
        guard await sudo.authorize(for: reason, report: report) else { return false }
        for app in missing {
            succeeded = await install(app, report: report) && succeeded
        }
        for app in removing {
            succeeded = await uninstall(app, report: report) && succeeded
        }
        return succeeded
    }

    /// The IDs of the installed App Store apps, or nil when mas is missing or can't list them.
    private func installedIDs(report: (Message) -> Void) async -> Set<Int>? {
        guard files.item(at: Mas.path) != nil else {
            report(
                Message(
                    .error,
                    """
                    couldn't install App Store apps: mas isn't installed at \(private: Mas.path), \
                    add mas = "formula" to [homebrew] in \(Paths.packagesTOMLName)
                    """))
            return nil
        }
        let result = await runner.run(Mas.installed)
        guard result.succeeded else {
            report(Message(.error, "couldn't list the installed App Store apps: \(result.reason)"))
            return nil
        }
        return Mas.ids(in: result.output)
    }

    /// Records `apps` as managed by Malum, since they were installed already.
    private func adopt(_ apps: [AppStoreApp], report: (Message) -> Void) -> Bool {
        guard !apps.isEmpty else { return true }
        let recorded = remember(report: report) { record in
            for app in apps { record.appStore[app.name] = app.id }
        }
        guard recorded else { return false }
        for app in apps {
            report(Message(.info, "App Store app \(app.name) was already installed, \(Project.name) manages it now"))
        }
        return true
    }

    /// Installs one app and records it. Says whether it worked.
    private func install(_ app: AppStoreApp, report: (Message) -> Void) async -> Bool {
        report(Message(.info, "installing App Store app \(app.name) (\(app.id))"))
        let result = await runner.run(Mas.install(app.id))
        guard result.succeeded else {
            report(Message(.error, "couldn't install App Store app \(app.name): \(result.reason)"))
            return false
        }
        report(Message(.info, "installed App Store app \(app.name)"))
        return remember(report: report) { $0.appStore[app.name] = app.id }
    }

    /// Uninstalls one app Malum manages and takes it out of the record. Says whether it worked.
    private func uninstall(_ app: AppStoreApp, report: (Message) -> Void) async -> Bool {
        report(Message(.info, "uninstalling App Store app \(app.name) (\(app.id))"))
        let result = await runner.run(Mas.uninstall(app.id))
        guard result.succeeded else {
            report(Message(.error, "couldn't uninstall App Store app \(app.name): \(result.reason)"))
            return false
        }
        report(Message(.info, "uninstalled App Store app \(app.name)"))
        return remember(report: report) { $0.appStore[app.name] = nil }
    }

    /// Makes `change` to the record. Says whether it worked.
    private func remember(report: (Message) -> Void, _ change: (inout InstalledRecord) -> Void) -> Bool {
        do {
            try InstalledRecord.change(in: state, change)
            return true
        } catch {
            report(Message(.error, "couldn't record what \(Project.name) installed: \(MessageText(error: error))"))
            return false
        }
    }

    /// What the password is asked for, when apps are `installing`, `removing` or both.
    private static func reason(installing: Bool, removing: Bool) -> String {
        let actions = [installing ? "install" : nil, removing ? "uninstall" : nil].compactMap { $0 }
        return "\(actions.joined(separator: " and ")) App Store apps"
    }
}
