/// The words of the menu bar icon and its menu.
extension StatusMenu {
    /// The icon's name for screen readers and its tooltip, which says when something is wrong.
    public var label: String {
        needsAttention ? "\(Project.name) needs attention" : Project.name
    }

    /// The top line: the app and its version.
    static var title: String { "\(Project.name) \(Project.version)" }

    /// The line in place of the modules while there are none.
    static var noModules: String { "no modules yet" }

    /// The line for one module and its status.
    static func moduleLine(_ module: String, _ status: ModuleStatus) -> String {
        "\(module): \(status)"
    }

    /// Why safe mode is on.
    static func safeMode(_ reason: SafeModeReason) -> String {
        "safe mode: \(reason)"
    }

    /// The way out of safe mode.
    static var leaveSafeMode: String { "Leave safe mode" }

    /// The way to enable `module` again.
    static func enable(_ module: String) -> String {
        "Enable \(module)"
    }

    /// The way to grant `permission`.
    static func openSettings(_ permission: Permission) -> String {
        "Open \(permission) settings"
    }

    /// The line in place of the problems while `malum.toml` has none.
    static var noConfigProblems: String { "\(Paths.configTOMLName) has no problems" }

    /// The way to the dots folder when `malum.toml` is missing.
    static var showDotsFolder: String { "Show dots folder" }

    /// The way to open `malum.toml`.
    static var openConfig: String { "Open \(Paths.configTOMLName)" }

    /// The way to load `malum.toml` again.
    static var reload: String { "Reload \(Paths.configTOMLName)" }

    /// The way to quit.
    static var quit: String { "Quit \(Project.name)" }
}
