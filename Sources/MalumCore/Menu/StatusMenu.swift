/// What the menu bar icon shows: each module's state, missing permissions and config problems,
/// each with a way to fix it.
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
        items =
            [.text(Self.title), .separator]
            + Self.signingItems(signingProblem)
            + Self.safeModeItems(overrides.safeMode)
            + Self.moduleItems(modules) + Self.disabledItems(overrides.disabled) + [.separator]
            + Self.configItems(problems, path: configPath, exists: configExists) + [.separator]
            + [.action(Self.reload, .reload), .action(Self.quit, .quit)]
        needsAttention =
            !problems.isEmpty || overrides.safeMode != nil || signingProblem != nil
            || modules.contains { Self.needsAttention($0.status) }
    }

    /// Why the modules stay off unsigned, or nothing when Malum is signed.
    private static func signingItems(_ problem: String?) -> [MenuItem] {
        guard let problem else { return [] }
        return [.text(problem), .separator]
    }

    /// Why safe mode is on and the way out of it, or nothing while it's off.
    private static func safeModeItems(_ reason: SafeModeReason?) -> [MenuItem] {
        guard let reason else { return [] }
        return [.text(safeMode(reason)), .action(leaveSafeMode, .leaveSafeMode), .separator]
    }

    /// A way to enable each disabled module, in a steady order.
    private static func disabledItems(_ disabled: Set<String>) -> [MenuItem] {
        disabled.sorted().map { .action(enable($0), .enable($0)) }
    }

    /// A line per module with its status, and a way to grant each permission it's missing.
    private static func moduleItems(_ modules: [(id: String, status: ModuleStatus)]) -> [MenuItem] {
        guard !modules.isEmpty else { return [.text(noModules)] }
        return modules.flatMap { module in
            [.text(moduleLine(module.id, module.status))] + permissionItems(module.status)
        }
    }

    /// A way to grant each missing permission, in a steady order.
    private static func permissionItems(_ status: ModuleStatus) -> [MenuItem] {
        guard case .needsPermission(let missing) = status else { return [] }
        return missing.sorted { $0.description < $1.description }
            .map { .action(openSettings($0), .openSettings($0)) }
    }

    /// The problems `malum.toml` has, and a way to get to the file: open it, or show the dots
    /// folder when it's missing. Without dots, the problem itself says what to run.
    private static func configItems(_ problems: [Message], path: String?, exists: Bool) -> [MenuItem] {
        let lines: [MenuItem] =
            problems.isEmpty
            ? [.text(noConfigProblems)] : problems.map { .text($0.description) }
        guard let path else { return lines }
        guard exists else { return lines + [.action(showDotsFolder, .showFolder(folder(of: path)))] }
        return lines + [.action(openConfig, .openFile(path))]
    }

    /// The folder that holds `path`.
    private static func folder(of path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else { return path }
        return String(path[..<slash])
    }

    /// Whether a module's status should change the icon.
    private static func needsAttention(_ status: ModuleStatus) -> Bool {
        switch status {
        case .degraded, .failed, .needsPermission:
            true
        case .off, .starting, .running:
            false
        }
    }
}
