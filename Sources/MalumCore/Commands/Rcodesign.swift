/// Every way Malum runs `rcodesign`, which signs with a key file instead of the keychain.
public enum Rcodesign {
    /// Seconds signing may take: a whole app bundle is hashed.
    private static let signingTimeoutSeconds = 120

    /// What `--timestamp-url` takes to leave the time stamp out, so signing works offline.
    private static let noTimestamp = "none"

    /// Signs the app bundle at `bundle` with `identity`'s key file and designated requirement,
    /// replacing the signature it has, using the `rcodesign` at `tool`.
    public static func sign(_ bundle: String, identity: SigningIdentity, tool: String) -> Command {
        Command(
            tool,
            [
                "sign", "--pem-file", identity.keyFile, "--code-requirements-path", identity.requirement,
                "--timestamp-url", noTimestamp, bundle,
            ],
            timeoutSeconds: signingTimeoutSeconds)
    }
}
