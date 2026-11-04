/// What the menu bar icon shows: each module's state, missing permissions and config problems,
/// each with a way to fix it.
public struct StatusMenu: Equatable, Sendable {
    /// The menu's lines, top to bottom.
    public let items: [MenuItem]
    /// Whether something is wrong, so the icon should say so.
    public let needsAttention: Bool

    /// Builds the menu from the modules, in their order, and the last load of `malum.toml`, which
    /// was looked for at `configPath`, where it may or may not exist. Both are nil before the first
    /// load; the path is nil when dots isn't known.
    public init(
        modules: [(id: String, status: ModuleStatus)], report: ConfigReport?, configPath: String?, configExists: Bool
    ) {
        let problems = report.map { $0.messages.filter { $0.level != .info } } ?? []
        items =
            [.text("\(Project.name) \(Project.version)"), .separator]
            + Self.moduleItems(modules) + [.separator]
            + Self.configItems(problems, path: configPath, exists: configExists) + [.separator]
            + [.action("Reload \(Paths.configTOMLName)", .reload), .action("Quit \(Project.name)", .quit)]
        needsAttention = !problems.isEmpty || modules.contains { Self.needsAttention($0.status) }
    }

    /// A line per module with its status, and a way to grant each permission it's missing.
    private static func moduleItems(_ modules: [(id: String, status: ModuleStatus)]) -> [MenuItem] {
        guard !modules.isEmpty else { return [.text("no modules yet")] }
        return modules.flatMap { module in
            [.text("\(module.id): \(module.status)")] + permissionItems(module.status)
        }
    }

    /// A way to grant each missing permission, in a steady order.
    private static func permissionItems(_ status: ModuleStatus) -> [MenuItem] {
        guard case .needsPermission(let missing) = status else { return [] }
        return missing.sorted { $0.description < $1.description }
            .map { .action("Open \($0) settings", .openSettings($0)) }
    }

    /// The problems `malum.toml` has, and a way to get to the file: open it, or show the dots
    /// folder when it's missing. Without dots, the problem itself says what to run.
    private static func configItems(_ problems: [Message], path: String?, exists: Bool) -> [MenuItem] {
        let lines: [MenuItem] =
            problems.isEmpty
            ? [.text("\(Paths.configTOMLName) has no problems")] : problems.map { .text($0.description) }
        guard let path else { return lines }
        guard exists else { return lines + [.action("Show dots folder", .showFolder(folder(of: path)))] }
        return lines + [.action("Open \(Paths.configTOMLName)", .openFile(path))]
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
