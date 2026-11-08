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
        guard let record = InstalledRecord.read(from: state, for: .installAppStoreApps, report: report) else {
            return false
        }
        return await sync.run(listed: apps, managed: Self.managed(in: record), report: report)
    }

    /// Reports how the apps in `apps` and the ones `record` holds look now, changing nothing. Says
    /// whether it could tell.
    func status(_ apps: [AppStoreApp], record: InstalledRecord, report: (Message) -> Void) async -> Bool {
        await sync.status(listed: apps, managed: Self.managed(in: record), report: report)
    }

    /// Brings apps in line through `mas`.
    private var sync: ManagedSync<Kind> {
        ManagedSync(installer: Kind(runner: runner, files: files, sudo: sudo), state: state)
    }

    /// The apps `record` holds, by name.
    private static func managed(in record: InstalledRecord) -> [AppStoreApp] {
        record.appStore.sorted { $0.key < $1.key }.map { AppStoreApp($0.key, id: $0.value) }
    }

    /// How App Store apps are installed with `mas`.
    private struct Kind: Installer {
        let runner: any CommandRunner
        let files: any FileSystem
        let sudo: SudoSession

        var label: MessageText { .appStoreApp }

        var plural: MessageText { .appStoreApps }

        func key(of item: AppStoreApp) -> String { String(item.id) }

        func name(of item: AppStoreApp) -> String { item.name }

        func shown(_ item: AppStoreApp) -> String { "\(item.name) (\(item.id))" }

        func installed(report: (Message) -> Void) async -> ((AppStoreApp) -> Bool)? {
            guard files.item(at: Mas.path) != nil else {
                report(.noMas)
                return nil
            }
            let result = await runner.run(Mas.installed)
            guard result.succeeded else {
                report(.unlistable(.appStoreApps, reason: result.reason))
                return nil
            }
            let ids = Mas.ids(in: result.output)
            return { ids.contains($0.id) }
        }

        /// Asks for the password once, since mas installs and uninstalls as root.
        func prepare(installing: Bool, removing: Bool, report: (Message) -> Void) async -> Bool {
            await sudo.authorize(for: .changeAppStoreApps(installing: installing, removing: removing), report: report)
        }

        func install(_ item: AppStoreApp) async -> CommandResult {
            await runner.run(Mas.install(item.id))
        }

        func uninstall(_ item: AppStoreApp) async -> Uninstalled {
            let result = await runner.run(Mas.uninstall(item.id))
            return result.succeeded ? .done : .failed(reason: result.reason)
        }

        func record(_ item: AppStoreApp, managed: Bool, in record: inout InstalledRecord) {
            record.appStore[item.name] = managed ? item.id : nil
        }
    }
}
