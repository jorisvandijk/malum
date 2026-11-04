/// `malum run`: reads system config's settings from `malum.toml` and makes the Mac match them.
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
        let settings = reloader.settings[SystemConfig.id] ?? [:]
        let succeeded = await HomebrewPackages(runner: runner, files: files).run(settings, report: report)
        report(
            succeeded
                ? Message(.info, "\(SystemConfig.id) is done")
                : Message(.error, "\(SystemConfig.id) finished with errors"))
        return succeeded
    }
}
