import Foundation

/// The app config files part of system config: reads each app's file in `apps/` in dots, and
/// writes the config files and sets the preferences it asks for.
@MainActor
public struct AppConfigFiles {
    /// The disk.
    private let files: any FileSystem
    /// Runs `defaults`.
    private let runner: any CommandRunner
    /// Where the record of what Malum wrote is kept.
    private let state: StateFolder
    /// Where the home folder is.
    private let paths: Paths

    /// Creates the part, which works on `files`, sets preferences with `runner` and keeps its
    /// record in `state`.
    public init(files: any FileSystem, runner: any CommandRunner, state: StateFolder, paths: Paths) {
        self.files = files
        self.runner = runner
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
        }
        let wrote = AppFileWriter(files: files, state: state, paths: paths).write(
            wanted, keeping: broken, report: report)
        let set = await AppPreferenceWriter(runner: runner, state: state).write(
            preferences, keeping: broken, report: report)
        return wrote && set && broken.isEmpty
    }

    /// The files and preferences `app` asks for in its file at `path`, or nil when an error in it
    /// stops them.
    private func read(
        _ app: AppConfig, from path: String, report: (Message) -> Void
    ) -> (files: [AppFile], preferences: [AppPreference])? {
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
