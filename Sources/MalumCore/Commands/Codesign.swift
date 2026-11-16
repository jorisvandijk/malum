/// Every way Malum runs `codesign`, which only checks signatures: `rcodesign` makes them.
public enum Codesign {
    /// The tool.
    private static let path = "/usr/bin/codesign"

    /// Checks that the bundle at `bundle` is intact and signed with the certificate whose SHA-1 is
    /// `identity`.
    public static func verify(_ bundle: String, identity: String) -> Command {
        Command(path, ["--verify", "--strict", "--test-requirement", "=certificate leaf = H\"\(identity)\"", bundle])
    }
}
