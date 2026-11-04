/// Every way Malum runs `mas`, the App Store's command line, which Homebrew installs.
public enum Mas {
    /// Where Homebrew puts `mas` on Apple silicon.
    public static let path = "/opt/homebrew/bin/mas"
    /// Seconds one install may take: Xcode alone downloads many gigabytes.
    private static let installTimeoutSeconds = 7200

    /// Lists the installed App Store apps, one per line, as `497799835  Xcode  (26.0)`.
    public static let installed = Command(path, ["list"])

    /// Gets and installs the App Store app with `id`. mas needs root for this.
    public static func install(_ id: Int) -> Command {
        Sudo.asRoot(Command(path, ["get", String(id)], timeoutSeconds: installTimeoutSeconds))
    }

    /// The App Store IDs in the output of `installed`.
    public static func ids(in output: String) -> Set<Int> {
        Set(
            output.split(separator: "\n").compactMap { line in
                Int(line.drop { $0 == " " }.prefix { $0.isNumber })
            })
    }
}
