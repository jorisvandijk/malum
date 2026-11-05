/// Every way Malum runs `codesign`.
public enum Codesign {
    /// The tool.
    static let path = "/usr/bin/codesign"
    /// Seconds signing may take: the first time, macOS asks for the login password before codesign
    /// may use the key.
    private static let signingTimeoutSeconds = 300

    /// Signs the app bundle at `bundle` with the certificate whose SHA-1 is `identity`, replacing
    /// the signature it has. No timestamp, since that needs Apple's server and a paid account.
    public static func sign(_ bundle: String, identity: String) -> Command {
        Command(
            path, ["--force", "--sign", identity, "--timestamp=none", bundle], timeoutSeconds: signingTimeoutSeconds)
    }

    /// Checks that the bundle at `bundle` is intact and signed with the certificate whose SHA-1 is
    /// `identity`.
    public static func verify(_ bundle: String, identity: String) -> Command {
        Command(path, ["--verify", "--strict", "--test-requirement", "=certificate leaf = H\"\(identity)\"", bundle])
    }
}
