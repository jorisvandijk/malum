/// `malum run`: checks that system config is switched on in `malum.toml`, and makes the Mac match dots.
@MainActor
public struct RunCommand {
    /// The disk.
    private let files: any FileSystem
    /// Where Malum's own files go.
    private let paths: Paths
    /// Runs the outside tools.
    private let runner: any CommandRunner
    /// Looks up and downloads GitHub releases.
    private let github: any GitHub
    /// The locks of the state folder.
    private let locks: any FileLocks
    /// Whether it runs in a terminal, where sudo can ask for the password.
    private let canAsk: Bool
    /// Says which app opens what, and changes it.
    private let handlers: any AppHandlers

    /// Creates the command, which asks for the password only when `canAsk` is set and sets the
    /// default apps through `handlers`.
    public init(
        files: any FileSystem, paths: Paths, runner: any CommandRunner, github: any GitHub, locks: any FileLocks,
        canAsk: Bool, handlers: any AppHandlers
    ) {
        self.files = files
        self.paths = paths
        self.runner = runner
        self.github = github
        self.locks = locks
        self.canAsk = canAsk
        self.handlers = handlers
    }

    /// Loads `malum.toml` and runs each part of system config in order, reporting as it goes. Says
    /// whether everything worked.
    public func run(report: (Message) -> Void) async -> Bool {
        let reloader = ConfigReloader(files: files, paths: paths, schemas: ConfigSchemas.all(modules: []))
        guard let config = reloader.reload(force: true) else { return false }
        config.problems.map(\.message).forEach(report)
        guard let loaded = config.loaded else { return false }
        guard !config.kept.contains(SystemConfig.id) else {
            report(.systemConfigNeedsFix(in: loaded))
            return false
        }
        guard reloader.enabled.contains(SystemConfig.id) else {
            report(.systemConfigOff(in: loaded))
            return false
        }
        let folders = ReleaseFolders(reloader.settings[SystemConfig.id] ?? [:], paths: paths)
        let succeeded: Bool
        do {
            guard let dots = try DotsPointer(files: files, paths: paths).read() else { return false }
            let state = StateFolder(files: files, locks: locks, paths: paths)
            let sudo = SudoSession(runner: runner, canAsk: canAsk)
            defer { sudo.end() }
            let packages = await installPackages(dots: dots, folders: folders, sudo: sudo, state: state, report: report)
            let apps = await AppConfigFiles(files: files, runner: runner, sudo: sudo, state: state, paths: paths).run(
                dots: dots, report: report)
            let macOS = await MacOSSettings(
                files: files, runner: runner, sudo: sudo, state: state, paths: paths, handlers: handlers
            ).run(dots: dots, report: report)
            succeeded = packages && apps && macOS
        } catch {
            report(.failed(error))
            return false
        }
        report(.systemConfigFinished(succeeded: succeeded))
        return succeeded
    }

    /// Reads `packages.toml` from the dots folder `dots` and installs what it lists, asking for the
    /// password through `sudo`. Says whether everything worked.
    private func installPackages(
        dots: String, folders: ReleaseFolders, sudo: SudoSession, state: StateFolder, report: (Message) -> Void
    ) async -> Bool {
        let file = paths.packagesTOML(in: dots)
        do {
            guard files.item(at: file) != nil else {
                report(.nothingToInstall(missing: file))
                return true
            }
            let (list, problems) = PackageList.read(try files.read(file))
            problems.map(\.message).forEach(report)
            guard let list else {
                report(.needsFix(.installPackages, file))
                return false
            }
            let homebrew = await HomebrewPackages(runner: runner, files: files, state: state).run(
                list.homebrew, report: report)
            let appStore = await AppStoreApps(runner: runner, files: files, sudo: sudo, state: state).run(
                list.appStore, report: report)
            let releases = await GitHubReleases(
                github: github, runner: runner, files: files, state: state, folders: folders
            ).run(list.releases, report: report)
            return homebrew && appStore && releases
        } catch {
            report(.failed(error))
            return false
        }
    }
}
