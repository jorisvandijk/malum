/// Every way Malum runs `ditto`, which unpacks zip files the way Finder does.
public enum Ditto {
    /// Where macOS keeps `ditto`.
    public static let path = "/usr/bin/ditto"
    /// Seconds one unpack may take.
    private static let unpackTimeoutSeconds = 300

    /// Unpacks the zip file `archive` into the folder `folder`.
    public static func unzip(_ archive: String, into folder: String) -> Command {
        Command(path, ["-x", "-k", archive, folder], timeoutSeconds: unpackTimeoutSeconds)
    }
}
