/// `malum status`: shows what Malum manages, and what doesn't match dots right now, changing nothing.
@MainActor
public struct StatusCommand {
    /// The disk.
    private let files: any FileSystem
    /// Where Malum's own files go.
    private let paths: Paths
    /// Runs the outside tools that say what's installed.
    private let runner: any CommandRunner
    /// The locks of the state folder.
    private let locks: any FileLocks

    /// Creates the command, which asks the outside tools through `runner` what's installed.
    public init(files: any FileSystem, paths: Paths, runner: any CommandRunner, locks: any FileLocks) {
        self.files = files
        self.paths = paths
        self.runner = runner
        self.locks = locks
    }

    /// Reports how many of each kind Malum manages, and each thing that doesn't match dots: listed
    /// but not installed, not listed anymore, missing, or changed outside Malum. Says whether it
    /// could tell everything.
    public func run(report: (Message) -> Void) async -> Bool {
        let state = StateFolder(files: files, locks: locks, paths: paths)
        let dots: String
        let record: InstalledRecord
        do {
            guard let found = try DotsPointer(files: files, paths: paths).read() else {
                report(.statusNoDots)
                return false
            }
            dots = found
            record = try InstalledRecord.read(from: state)
        } catch {
            report(.failed(.showStatus, error))
            return false
        }
        var mismatches = 0
        func note(_ message: Message) {
            if message.level == .warn { mismatches += 1 }
            report(message)
        }
        // Nothing here asks for the password; the parts only need a session to be built.
        let sudo = SudoSession(runner: runner, canAsk: false)
        let packages = await packages(in: dots, record: record, sudo: sudo, state: state, report: note)
        let extensions = await VSCodiumExtensions(runner: runner, files: files, state: state).status(
            record: record, report: note)
        let appFiles = check(record.files.mapValues(\.fingerprint), .appFiles, report: note)
        count(record.preferences, .appPreferences, report: note)
        count(record.macOS, .macOSSettings, report: note)
        let systemFiles = check(record.systemFiles, .systemFiles, report: note)
        let power = await PowerSettings(runner: runner, sudo: sudo, state: state).status(record.power, report: note)
        let known = packages && extensions && appFiles && systemFiles && power
        if known && mismatches == 0 { report(.statusMatches) }
        return known
    }

    /// Reports how what `packages.toml` in the dots folder `dots` lists, and what `record` holds,
    /// look now. Says whether it could tell.
    private func packages(
        in dots: String, record: InstalledRecord, sudo: SudoSession, state: StateFolder, report: (Message) -> Void
    ) async -> Bool {
        let file = paths.packagesTOML(in: dots)
        var list = PackageList()
        do {
            if files.item(at: file) != nil {
                let (read, problems) = PackageList.read(try files.read(file))
                problems.map(\.message).forEach(report)
                guard let read else {
                    report(.needsFix(.showStatus, file))
                    return false
                }
                list = read
            }
        } catch {
            report(.failed(.showStatus, error))
            return false
        }
        let homebrew = await HomebrewPackages(runner: runner, files: files, state: state).status(
            list.homebrew, record: record, report: report)
        let appStore = await AppStoreApps(runner: runner, files: files, sudo: sudo, state: state).status(
            list.appStore, record: record, report: report)
        GitHubReleases.status(list.releases, record: record, files: files, report: report)
        return homebrew && appStore
    }

    /// Reports how many files `managed` holds, by path with the fingerprint of what Malum wrote,
    /// and each one that's missing or was changed since. Says whether it could tell.
    private func check(_ managed: [String: String], _ plural: MessageText, report: (Message) -> Void) -> Bool {
        guard !managed.isEmpty else { return true }
        report(.statusManaged(managed.count, plural))
        var known = true
        for (path, fingerprint) in managed.sorted(by: { $0.key < $1.key }) {
            guard let item = files.item(at: path) else {
                report(.statusMissing(path))
                continue
            }
            do {
                let text = item == .file ? try files.read(path) : nil
                if text.map(ManagedFile.fingerprint) != fingerprint { report(.statusChanged(path)) }
            } catch {
                report(.failed(.showStatus, error))
                known = false
            }
        }
        return known
    }

    /// Reports how many preferences `managed` holds, by domain.
    private func count(_ managed: [String: ManagedPreferences], _ plural: MessageText, report: (Message) -> Void) {
        guard !managed.isEmpty else { return }
        report(.statusManaged(managed.values.map(\.keys.count).reduce(0, +), plural))
    }
}
