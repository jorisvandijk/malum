/// Reads `malum.toml` and the modules' own files from dots, and reads them again when asked, keeping
/// each module's last good settings.
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
    /// The files a change to which needs a reload: `malum.toml` and each module's own file, whether
    /// it's there or not. Empty when dots isn't known.
    public private(set) var watchedFiles: [String] = []

    /// Creates a reloader for the modules with these schemas, with nothing read yet.
    public init(files: any FileSystem, paths: Paths, schemas: [String: ConfigSchema]) {
        self.files = files
        self.paths = paths
        config = Config(schemas: schemas)
    }

    /// Each module's last good settings, by the module's id.
    public var settings: [String: ConfigTable] { config.settings }
    /// Each module's last good settings with the checked text of its own file, by the module's id.
    public var moduleSettings: [String: ModuleSettings] { config.moduleSettings }
    /// The modules switched on, by their last good table.
    public var enabled: Set<String> { config.enabled }

    /// Reads `malum.toml` and the modules' own files again and checks them.
    ///
    /// Unless `force` is set, a read that gives the same as last time returns nil, so a save
    /// without changes, or one save seen twice, reloads nothing.
    public func reload(force: Bool) -> ConfigReport? {
        let source = read()
        guard force || source != last else { return nil }
        last = source
        switch source {
        case .text(let path, let text, let modules):
            return config.load(text, from: path, moduleFiles: modules)
        case .noDots:
            return failed(.noDotsYet)
        case .missing(let path):
            return failed(.configMissing(path))
        case .unreadable(let error):
            return failed(error.text)
        }
    }

    /// Finds dots and reads `malum.toml` and the modules' own files from it.
    private func read() -> ConfigSource {
        path = nil
        watchedFiles = []
        let dots: String?
        do {
            dots = try DotsPointer(files: files, paths: paths).read()
        } catch {
            return .unreadable(error)
        }
        guard let dots else { return .noDots }
        let file = paths.configTOML(in: dots)
        let moduleFiles = config.modules.sorted().map { (module: $0, path: paths.moduleTOML($0, in: dots)) }
        path = file
        watchedFiles = [file] + moduleFiles.map(\.path)
        guard files.item(at: file) != nil else { return .missing(path: file) }
        do {
            return .text(path: file, try files.read(file), modules: readModuleFiles(moduleFiles))
        } catch {
            return .unreadable(error)
        }
    }

    /// The modules' own files that are there, by the module's id.
    private func readModuleFiles(_ moduleFiles: [(module: String, path: String)]) -> [String: ModuleFile] {
        var read: [String: ModuleFile] = [:]
        for (module, path) in moduleFiles {
            do {
                guard let text = try files.text(ifFileAt: path) else { continue }
                read[module] = .text(path: path, text)
            } catch {
                read[module] = .unreadable(path: path, error)
            }
        }
        return read
    }

    /// A report for a file that couldn't be read: every module keeps its settings.
    private func failed(_ text: MessageText) -> ConfigReport {
        ConfigReport(loaded: nil, changed: [], kept: config.modules, problems: [ConfigProblem(.error, text)])
    }
}
