/// Every way Malum runs `install`, which copies a file into place with its owner and mode set.
public enum Install {
    /// Where macOS keeps `install`.
    public static let path = "/usr/bin/install"

    /// Copies `source` to `destination` as a file owned by root that everyone can read. A link at
    /// `destination` is replaced, not written through. Only root can run it.
    public static func rootFile(_ source: String, to destination: String) -> Command {
        Command(path, ["-m", "0644", "-o", "root", "-g", "wheel", source, destination])
    }
}
