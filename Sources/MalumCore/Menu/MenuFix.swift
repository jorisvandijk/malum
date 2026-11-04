/// What a menu item does when it's picked.
public enum MenuFix: Equatable, Sendable {
    /// Opens a file in its default app, such as `malum.toml` in the user's editor.
    case openFile(String)
    /// Shows a folder in Finder.
    case showFolder(String)
    /// Opens the page in System Settings where a permission is granted.
    case openSettings(Permission)
    /// Loads `malum.toml` again.
    case reload
    /// Quits Malum.
    case quit
}
