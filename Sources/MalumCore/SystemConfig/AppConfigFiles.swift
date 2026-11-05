import Foundation

/// The app config files part of system config: reads each app's file in `apps/` in dots, and
/// writes the config files it asks for.
@MainActor
public struct AppConfigFiles {
    /// The disk.
    private let files: any FileSystem
    /// Where the record of what Malum wrote is kept.
    private let state: StateFolder
    /// Where the home folder is.
    private let paths: Paths

    /// Creates the part, which works on `files` and keeps its record in `state`.
    public init(files: any FileSystem, state: StateFolder, paths: Paths) {
        self.files = files
        self.state = state
        self.paths = paths
    }

    /// Writes the config files of each app in the dots folder `dots`, and removes the ones Malum
    /// wrote that no app asks for anymore, reporting each step as it goes. Says whether
    /// everything worked.
    public func run(dots: String, report: (Message) -> Void) -> Bool {
        let folder = paths.appsFolder(in: dots)
        guard files.item(at: folder) == .directory else {
            report(Message(.info, "no app config files to write: \(private: folder) doesn't exist"))
            return true
        }
        let names: [String]
        do {
            names = try files.contents(of: folder).filter { ($0 as NSString).pathExtension == Paths.tomlExtension }
                .sorted()
        } catch {
            report(Message(.error, "couldn't write app config files: \(MessageText(error: error))"))
            return false
        }
        var wanted: [(app: String, file: AppFile)] = []
        var broken: Set<String> = []
        for fileName in names {
            let name = (fileName as NSString).deletingPathExtension
            guard let app = AppConfigs.app(named: name) else {
                report(Message(.warn, "\(Paths.appFile(named: name)): \(Project.name) has no app called \(name)"))
                continue
            }
            guard let appFiles = read(app, from: "\(folder)/\(fileName)", report: report) else {
                broken.insert(name)
                continue
            }
            wanted += appFiles.map { (name, $0) }
        }
        let writer = AppFileWriter(files: files, state: state, paths: paths)
        return writer.write(wanted, keeping: broken, report: report) && broken.isEmpty
    }

    /// The files `app` asks for in its file at `path`, or nil when an error in it stops them.
    private func read(_ app: AppConfig, from path: String, report: (Message) -> Void) -> [AppFile]? {
        let fileName = Paths.appFile(named: app.name)
        let fixFirst = Message(.error, "couldn't write \(app.name)'s config files: fix \(private: path) first")
        var reader: TableReader
        do {
            reader = try TableReader(try files.read(path), file: fileName)
        } catch let problem as ConfigProblem {
            report(problem.message)
            report(fixFirst)
            return nil
        } catch {
            report(Message(.error, "couldn't write \(app.name)'s config files: \(MessageText(error: error))"))
            return nil
        }
        let appFiles = app.read(&reader)
        reader.problems.map(\.message).forEach(report)
        guard !reader.hasErrors else {
            report(fixFirst)
            return nil
        }
        return appFiles
    }
}
