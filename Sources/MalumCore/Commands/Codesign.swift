/// Every way Malum runs `codesign`.
public enum Codesign {
    /// The tool.
    private static let path = "/usr/bin/codesign"

    /// Signs the app bundle at `bundle` with the certificate whose SHA-1 is `identity`, replacing
    /// the signature it has. No timestamp, since that needs Apple's server and a paid account.
    public static func sign(_ bundle: String, identity: String) -> Command {
        Command(path, ["--force", "--sign", identity, "--timestamp=none", bundle])
    }

    /// Checks that the bundle at `bundle` is intact and signed with the certificate whose SHA-1 is
    /// `identity`.
    public static func verify(_ bundle: String, identity: String) -> Command {
        Command(path, ["--verify", "--strict", "--test-requirement", "=certificate leaf = H\"\(identity)\"", bundle])
    }
}
