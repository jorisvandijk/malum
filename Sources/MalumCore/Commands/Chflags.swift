/// Every way Malum runs `chflags`, which sets a file's flags, such as the one that hides it in Finder.
public enum Chflags {
    /// Where macOS keeps `chflags`.
    public static let path = "/usr/bin/chflags"

    /// Hides `item` in Finder.
    public static func hide(_ item: String) -> Command {
        Command(path, ["hidden", item])
    }

    /// Shows `item` in Finder again.
    public static func show(_ item: String) -> Command {
        Command(path, ["nohidden", item])
    }
}
