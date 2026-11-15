/// What a menu item does when it's picked.
public enum MenuFix: Equatable, Sendable {
    /// Opens a file in its default app, such as `malum.toml` in the user's editor.
    case openFile(String)
    /// Shows a folder in Finder.
    case showFolder(String)
    /// Opens the page in System Settings where a permission is granted.
    case openSettings(Permission)
    /// Runs system config, as `malum run` does, showing what it reports in the popup.
    case run
    /// Shows Malum's log of the last hour in the popup.
    case showLog
    /// Loads `malum.toml` and the modules' own files again and restarts every module.
    case reload
    /// Turns safe mode off, so the modules start as `malum.toml` says.
    case leaveSafeMode
    /// Lets a disabled module run again, by its id.
    case enable(String)
    /// Shows the About window: the logo, the version, who makes Malum and its website.
    case about
    /// Quits Malum.
    case quit
}
