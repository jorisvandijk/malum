/// What the menu bar icon shows: each problem at the top as a way to fix it, then Malum's actions.
/// When all is well, the menu holds only the actions.
public struct StatusMenu: Equatable, Sendable {
    /// The menu's lines, top to bottom.
    public let items: [MenuItem]
    /// Whether something is wrong, so the icon should say so.
    public let needsAttention: Bool

    /// Builds the menu from the modules, in their order, the last load of `malum.toml`, which
    /// was looked for at `configPath`, where it may or may not exist, the `overrides`, and why the
    /// modules stay off unsigned. The report and the path are nil before the first load; the path is
    /// nil when dots isn't known.
    public init(
        modules: [(id: String, status: ModuleStatus)], report: ConfigReport?, configPath: String?, configExists: Bool,
        overrides: Overrides = Overrides(), signingProblem: String? = nil
    ) {
        let problems = report.map { $0.messages.filter { $0.level != .info } } ?? []
        let configFix = Self.configFix(path: configPath, exists: configExists)
        let fixes =
            Self.signingItems(signingProblem) + Self.safeModeItems(overrides.safeMode)
            + Self.disabledItems(overrides.disabled) + modules.flatMap(Self.moduleItems)
            + problems.map { .action($0.description, configFix) }
        let inspects = modules.contains { $0.id == WindowManagerConfig.module && $0.status.isActive }
        items = (fixes.isEmpty ? [] : fixes + [.separator]) + Self.actionItems(inspects: inspects)
        needsAttention = !fixes.isEmpty
    }

    /// Malum's own actions: run system config, inspect a window while the window manager runs
    /// (`inspects`), show the log, reload, about and quit.
    private static func actionItems(inspects: Bool) -> [MenuItem] {
        let inspect: [MenuItem] = inspects ? [.action(inspectWindow, .inspectWindow)] : []
        return [.action(run, .run)] + inspect + [
            .action(showLog, .showLog), .action(reload, .reload), .separator, .action(about, .about),
            .action(quit, .quit),
        ]
    }

    /// Why the modules stay off unsigned, which the log tells more about, or nothing when Malum is signed.
    private static func signingItems(_ problem: String?) -> [MenuItem] {
        guard let problem else { return [] }
        return [.action(problem, .showLog)]
    }

    /// The way out of safe mode, saying why it's on, or nothing while it's off.
    private static func safeModeItems(_ reason: SafeModeReason?) -> [MenuItem] {
        guard let reason else { return [] }
        return [.action(leaveSafeMode(reason), .leaveSafeMode)]
    }

    /// A way to enable each disabled module, in a steady order.
    private static func disabledItems(_ disabled: Set<String>) -> [MenuItem] {
        disabled.sorted().map { .action(enable($0), .enable($0)) }
    }

    /// A way to grant each permission a module is missing, in a steady order, or a way to the log
    /// when it failed or runs with less. Nothing when it's fine.
    private static func moduleItems(_ module: (id: String, status: ModuleStatus)) -> [MenuItem] {
        switch module.status {
        case .needsPermission(let missing):
            return missing.sorted { $0.description < $1.description }
                .map { .action(openSettings($0, for: module.id), .openSettings($0)) }
        case .degraded, .failed:
            return [.action(moduleLine(module.id, module.status), .showLog)]
        case .off, .starting, .running:
            return []
        }
    }

    /// What picking a config problem does: open `malum.toml`, show the dots folder when it's
    /// missing, or show the log without dots, where the problem itself says what to run.
    private static func configFix(path: String?, exists: Bool) -> MenuFix {
        guard let path else { return .showLog }
        guard exists else { return .showFolder(folder(of: path)) }
        return .openFile(path)
    }

    /// The folder that holds `path`.
    private static func folder(of path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else { return path }
        return String(path[..<slash])
    }
}
