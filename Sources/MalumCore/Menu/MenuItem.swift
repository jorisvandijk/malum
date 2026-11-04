/// One line of the menu bar icon's menu.
public enum MenuItem: Equatable, Sendable {
    /// A line to read, which can't be picked.
    case text(String)
    /// A line that does something when it's picked.
    case action(String, MenuFix)
    /// A line between two groups.
    case separator
}
