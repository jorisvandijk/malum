/// Every way Malum runs `rm`, for files it can't remove through the file system because only root
/// can.
public enum Remove {
    /// Where macOS keeps `rm`.
    public static let path = "/bin/rm"

    /// Removes the file at `file`, and succeeds when it's already gone.
    public static func file(_ file: String) -> Command {
        Command(path, ["-f", file])
    }
}
