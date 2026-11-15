/// The part of `malum status` that says which modules the app runs: on or off in `malum.toml`, kept
/// off with `malum disable`, or every one off in safe mode. Changes nothing.
@MainActor
public struct ModuleOverview {
    /// The disk.
    private let files: any FileSystem
    /// Where Malum's own files go.
    private let paths: Paths
    /// Malum's state folder, which holds the overrides.
    private let state: StateFolder

    /// Creates the overview, which reads `malum.toml` from dots and the overrides from `state`.
    public init(files: any FileSystem, paths: Paths, state: StateFolder) {
        self.files = files
        self.paths = paths
        self.state = state
    }

    /// Reports safe mode when it's on, the problems in `malum.toml`, and a line per module, by id.
    public func report(_ report: (Message) -> Void) {
        let overrides: Overrides
        do {
            overrides = try OverrideStore(state: state).read()
        } catch {
            report(.failed(.showStatus, error))
            return
        }
        if let reason = overrides.safeMode { report(.statusSafeMode(reason)) }
        let reloader = ConfigReloader(files: files, paths: paths, schemas: ConfigSchemas.all)
        let loaded = reloader.reload(force: true)
        loaded.map { $0.messages.filter { $0.level != .info } }?.forEach(report)
        for module in Modules.schemas.keys.sorted() {
            report(line(module, enabled: reloader.enabled, overrides: overrides))
        }
    }

    /// The line for `module`.
    private func line(_ module: String, enabled: Set<String>, overrides: Overrides) -> Message {
        guard enabled.contains(module) else { return .statusModuleOff(module) }
        guard !overrides.disabled.contains(module) else { return .statusModuleDisabled(module) }
        guard overrides.safeMode == nil else { return .statusModuleSafe(module) }
        return .statusModuleOn(module)
    }
}
