import Foundation

/// The app config files part of system config: reads each app's file in `apps/` in dots, and
/// writes the config files, sets the preferences and installs the extensions it asks for.
@MainActor
public struct AppConfigFiles {
    /// The disk.
    private let files: any FileSystem
    /// Runs `defaults` and `codium`.
    private let runner: any CommandRunner
    /// Gets root for system-wide preferences.
    private let sudo: SudoSession
    /// Where the record of what Malum wrote is kept.
    private let state: StateFolder
    /// Where the home folder is.
    private let paths: Paths

    /// Creates the part, which works on `files`, sets preferences with `runner`, as root through
    /// `sudo` when they're system-wide, and keeps its record in `state`.
    public init(
        files: any FileSystem, runner: any CommandRunner, sudo: SudoSession, state: StateFolder, paths: Paths
    ) {
        self.files = files
        self.runner = runner
        self.sudo = sudo
        self.state = state
        self.paths = paths
    }

    /// Writes the config files and sets the preferences of each app in the dots folder `dots`, and
    /// removes the ones Malum wrote that no app asks for anymore, reporting each step as it goes.
    /// Says whether everything worked.
    public func run(dots: String, report: (Message) -> Void) async -> Bool {
        let folder = paths.appsFolder(in: dots)
        guard files.item(at: folder) == .directory else {
            report(.noAppsFolder(missing: folder))
            return true
        }
        let names: [String]
        do {
            names = try files.contents(of: folder).filter { ($0 as NSString).pathExtension == Paths.tomlExtension }
                .sorted()
        } catch {
            report(.failed(.writeAppFiles, error))
            return false
        }
        var wanted: [(app: String, file: AppFile)] = []
        var preferences: [(app: String, preference: AppPreference)] = []
        var extensions: [String] = []
        var broken: Set<String> = []
        for fileName in names {
            let name = (fileName as NSString).deletingPathExtension
            guard let app = AppConfigs.app(named: name) else {
                report(.unknownApp(name))
                continue
            }
            guard let settings = read(app, from: "\(folder)/\(fileName)", report: report) else {
                broken.insert(name)
                continue
            }
            wanted += settings.files.map { (name, $0) }
            preferences += settings.preferences.map { (name, $0) }
            extensions += settings.extensions
        }
        let wrote = AppFileWriter(files: files, state: state, paths: paths).write(
            wanted, keeping: broken, report: report)
        let set = await AppPreferenceWriter(runner: runner, files: files, sudo: sudo, state: state).write(
            preferences, keeping: broken, report: report)
        let installed = await install(extensions, keeping: broken, report: report)
        return wrote && set && installed && broken.isEmpty
    }

    /// Installs the extensions in `ids` and uninstalls the unlisted ones, unless an app with
    /// extensions is `broken`: an error in its file keeps them as they are. Says whether it worked.
    private func install(_ ids: [String], keeping broken: Set<String>, report: (Message) -> Void) async -> Bool {
        guard !AppConfigs.all.contains(where: { $0.extensions && broken.contains($0.name) }) else { return true }
        return await VSCodiumExtensions(runner: runner, files: files, state: state).run(ids, report: report)
    }

    /// What `app` asks for in its file at `path`, or nil when an error in it stops it.
    private func read(_ app: AppConfig, from path: String, report: (Message) -> Void) -> AppSettings? {
        let fileName = Paths.appFile(named: app.name)
        let fixFirst = Message.needsFix(.writeAppFiles(of: app.name), path)
        var reader: TableReader
        do {
            reader = try TableReader(try files.read(path), file: fileName)
        } catch let problem as ConfigProblem {
            report(problem.message)
            report(fixFirst)
            return nil
        } catch {
            report(.failed(.writeAppFiles(of: app.name), error))
            return nil
        }
        let settings = app.read(&reader)
        reader.problems.map(\.message).forEach(report)
        guard !reader.hasErrors else {
            report(fixFirst)
            return nil
        }
        return settings
    }
}
