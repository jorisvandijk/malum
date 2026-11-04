/// Every way Malum runs `tar`, which unpacks tarballs, compressed or not.
public enum Tar {
    /// Where macOS keeps `tar`.
    public static let path = "/usr/bin/tar"
    /// Seconds one unpack may take.
    private static let unpackTimeoutSeconds = 300

    /// Unpacks the tarball `archive` into the folder `folder`, which must exist.
    public static func unpack(_ archive: String, into folder: String) -> Command {
        Command(path, ["-x", "-f", archive, "-C", folder], timeoutSeconds: unpackTimeoutSeconds)
    }
}
