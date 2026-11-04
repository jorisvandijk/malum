/// Reads `malum.toml` from dots, and reads it again when asked, keeping each module's last good settings.
@MainActor
public final class ConfigReloader {
    /// The disk.
    private let files: any FileSystem
    /// Where Malum's own files go.
    private let paths: Paths
    /// The settings so far.
    private var config: Config
    /// What the last read gave, so a read that gives the same is skipped.
    private var last: ConfigSource?
    /// Where `malum.toml` was looked for last, or nil when dots isn't known.
    public private(set) var path: String?

    /// Creates a reloader for the modules with these schemas, with nothing read yet.
    public init(files: any FileSystem, paths: Paths, schemas: [String: ConfigSchema]) {
        self.files = files
        self.paths = paths
        config = Config(schemas: schemas)
    }

    /// Each module's last good settings, by the module's id.
    public var settings: [String: ConfigTable] { config.settings }
    /// The modules switched on, by their last good table.
    public var enabled: Set<String> { config.enabled }

    /// Reads `malum.toml` again and checks it.
    ///
    /// Unless `force` is set, a read that gives the same as last time returns nil, so a save
    /// without changes, or one save seen twice, reloads nothing.
    public func reload(force: Bool) -> ConfigReport? {
        let source = read()
        guard force || source != last else { return nil }
        last = source
        switch source {
        case .text(let path, let text):
            return config.load(text, from: path)
        case .noDots:
            return failed("couldn't load \(Paths.configTOMLName): no dots folder yet, run \(Project.command) init")
        case .missing(let path):
            return failed("couldn't load \(path): it doesn't exist")
        case .unreadable(let error):
            return failed(error.description)
        }
    }

    /// Finds dots and reads `malum.toml` from it.
    private func read() -> ConfigSource {
        path = nil
        let dots: String?
        do {
            dots = try DotsPointer(files: files, paths: paths).read()
        } catch {
            return .unreadable(error)
        }
        guard let dots else { return .noDots }
        let file = paths.configTOML(in: dots)
        path = file
        guard files.item(at: file) != nil else { return .missing(path: file) }
        do {
            return .text(path: file, try files.read(file))
        } catch {
            return .unreadable(error)
        }
    }

    /// A report for a file that couldn't be read: every module keeps its settings.
    private func failed(_ text: String) -> ConfigReport {
        ConfigReport(loaded: nil, changed: [], kept: config.modules, problems: [ConfigProblem(.error, text)])
    }
}
