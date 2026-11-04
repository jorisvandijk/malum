/// `malum run`: checks that system config is switched on in `malum.toml`, and makes the Mac match dots.
@MainActor
public struct RunCommand {
    /// The disk.
    private let files: any FileSystem
    /// Where Malum's own files go.
    private let paths: Paths
    /// Runs the outside tools.
    private let runner: any CommandRunner

    /// Creates the command.
    public init(files: any FileSystem, paths: Paths, runner: any CommandRunner) {
        self.files = files
        self.paths = paths
        self.runner = runner
    }

    // TODO: App Store apps, GitHub releases, app config files and macOS settings, as further parts.
    /// Loads `malum.toml` and runs each part of system config in order, reporting as it goes. Says
    /// whether everything worked.
    public func run(report: (Message) -> Void) async -> Bool {
        let reloader = ConfigReloader(files: files, paths: paths, schemas: ConfigSchemas.all(modules: []))
        guard let config = reloader.reload(force: true) else { return false }
        config.problems.map(\.message).forEach(report)
        guard let loaded = config.loaded else { return false }
        guard !config.kept.contains(SystemConfig.id) else {
            report(Message(.error, "couldn't run \(SystemConfig.id): fix its table in \(private: loaded) first"))
            return false
        }
        guard reloader.enabled.contains(SystemConfig.id) else {
            report(
                Message(
                    .error,
                    "couldn't run \(SystemConfig.id): it's off, set enabled = true in its table in \(private: loaded)"))
            return false
        }
        let succeeded = await installPackages(report: report)
        report(
            succeeded
                ? Message(.info, "\(SystemConfig.id) is done")
                : Message(.error, "\(SystemConfig.id) finished with errors"))
        return succeeded
    }

    /// Reads `packages.toml` from dots and installs what it lists. Says whether everything worked.
    private func installPackages(report: (Message) -> Void) async -> Bool {
        let file: String
        do {
            guard let dots = try DotsPointer(files: files, paths: paths).read() else { return false }
            file = paths.packagesTOML(in: dots)
            guard files.item(at: file) != nil else {
                report(Message(.info, "nothing to install: \(private: file) doesn't exist"))
                return true
            }
            let (list, problems) = PackageList.read(try files.read(file))
            problems.map(\.message).forEach(report)
            guard let list else {
                report(Message(.error, "couldn't install packages: fix \(private: file) first"))
                return false
            }
            return await HomebrewPackages(runner: runner, files: files).run(list.homebrew, report: report)
        } catch {
            report(Message(.error, error.text))
            return false
        }
    }
}
