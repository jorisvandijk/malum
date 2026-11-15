/// The words of the menu bar icon and its menu.
extension StatusMenu {
    /// The icon's name for screen readers and its tooltip, which says when something is wrong.
    public var label: String {
        needsAttention ? "\(Project.name) needs attention" : Project.name
    }

    /// The line for a module that failed or runs with less, and its status.
    static func moduleLine(_ module: String, _ status: ModuleStatus) -> String {
        "\(module): \(status)"
    }

    /// The way out of safe mode, with why it's on.
    static func leaveSafeMode(_ reason: SafeModeReason) -> String {
        "Leave safe mode (\(reason))"
    }

    /// The way to enable `module` again.
    static func enable(_ module: String) -> String {
        "Enable \(module)"
    }

    /// The way to grant `permission`, which `module` waits for.
    static func openSettings(_ permission: Permission, for module: String) -> String {
        "\(module): open \(permission) settings"
    }

    /// The way to run system config.
    static var run: String { "Run" }

    /// The way to Malum's log.
    static var showLog: String { "Show log" }

    /// The way to load the config again and restart every module.
    static var reload: String { "Reload" }

    /// The way to the About window.
    static var about: String { "About \(Project.name)" }

    /// The way to quit.
    static var quit: String { "Quit \(Project.name)" }
}
