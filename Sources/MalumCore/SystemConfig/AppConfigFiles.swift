/// The app config files part of system config: reads each app's file in `apps/` in dots, and
/// writes the config files it asks for.
@MainActor
public struct AppConfigFiles {
    /// The extension of the files in `apps/`.
    private static let tomlExtension = ".toml"

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
            names = try files.contents(of: folder).filter { $0.hasSuffix(Self.tomlExtension) }.sorted()
        } catch {
            report(Message(.error, "couldn't write app config files: \(MessageText(error: error))"))
            return false
        }
        var wanted: [(app: String, file: AppFile)] = []
        var broken: Set<String> = []
        for fileName in names {
            let name = String(fileName.dropLast(Self.tomlExtension.count))
            guard let app = AppConfigs.app(named: name) else {
                report(Message(.warn, "\(Paths.appsFolderName)/\(fileName): \(Project.name) has no app called \(name)"))
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
        let fileName = "\(Paths.appsFolderName)/\(app.name)\(Self.tomlExtension)"
        let text: String
        let table: ConfigTable
        do {
            text = try files.read(path)
            table = ConfigValue.table(try TOMLReader.table(from: text))
        } catch let error as TOMLReadError {
            report(Self.problem(error, in: fileName).message)
            report(Message(.error, "couldn't write \(app.name)'s config files: fix \(private: path) first"))
            return nil
        } catch {
            report(Message(.error, "couldn't write \(app.name)'s config files: \(MessageText(error: error))"))
            return nil
        }
        let lines = TOMLLines(text)
        let (appFiles, problems) = app.read(table)
        for problem in problems {
            report(
                ConfigProblem(
                    problem.level, file: fileName, line: lines.line(of: problem.path), MessageText(problem.text)
                ).message)
        }
        guard !problems.contains(where: { $0.level == .error }) else {
            report(Message(.error, "couldn't write \(app.name)'s config files: fix \(private: path) first"))
            return nil
        }
        return appFiles
    }

    /// A syntax error as a problem in `fileName`, at its line and column when the parser gave them.
    private static func problem(_ error: TOMLReadError, in fileName: String) -> ConfigProblem {
        switch error {
        case .syntax(let line, let column, let reason):
            ConfigProblem(.error, file: fileName, line: line, column: column, MessageText(reason))
        case .unreadable(let reason):
            ConfigProblem(.error, "couldn't read \(fileName): \(reason)")
        }
    }
}
