/// Every way Malum runs `openssl`, which on macOS is LibreSSL.
public enum OpenSSL {
    /// The tool.
    private static let path = "/usr/bin/openssl"
    /// How long the certificate lasts, in days: twenty years.
    private static let days = 7300

    /// Makes a self-signed certificate and its key, as set out in the config file `config`.
    public static func makeCertificate(key: String, certificate: String, config: String) -> Command {
        Command(
            path,
            [
                "req", "-x509", "-newkey", "rsa:2048", "-sha256", "-days", "\(days)", "-nodes",
                "-keyout", key, "-out", certificate, "-config", config, "-extensions", "ext",
            ])
    }

    /// Bundles the key and the certificate into the PKCS #12 file `output`, called `name` and
    /// protected with `password`. 3DES and SHA-1, the only kind the keychain imports.
    public static func bundle(
        key: String, certificate: String, name: String, password: String, output: String
    ) -> Command {
        Command(
            path,
            [
                "pkcs12", "-export", "-inkey", key, "-in", certificate, "-name", name,
                "-keypbe", "PBE-SHA1-3DES", "-certpbe", "PBE-SHA1-3DES", "-macalg", "sha1",
                "-out", output, "-passout", "pass:\(password)",
            ])
    }
}
