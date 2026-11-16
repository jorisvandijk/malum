import Foundation

/// Every way Malum runs `openssl`, which on macOS is LibreSSL.
public enum OpenSSL {
    /// The tool.
    private static let path = "/usr/bin/openssl"
    /// How long the certificate lasts, in days: twenty years.
    private static let days = 7300
    /// The length of a SHA-1, in hex.
    private static let sha1Length = 40

    /// Makes a self-signed certificate and its key, as set out in the config file `config`.
    public static func makeCertificate(key: String, certificate: String, config: String) -> Command {
        Command(
            path,
            [
                "req", "-x509", "-newkey", "rsa:2048", "-sha256", "-days", "\(days)", "-nodes",
                "-keyout", key, "-out", certificate, "-config", config, "-extensions", "ext",
            ])
    }

    /// Prints the SHA-1 fingerprint of the first certificate in the PEM file `file`.
    public static func fingerprint(_ file: String) -> Command {
        Command(path, ["x509", "-in", file, "-noout", "-fingerprint", "-sha1"])
    }

    /// The SHA-1 in the output of `fingerprint`, a line like `SHA1 Fingerprint=3F:2A:…:9C`, in
    /// plain uppercase hex. Nil when there's none.
    public static func sha1(in output: String) -> String? {
        guard let value = output.split(separator: "=").last else { return nil }
        let hash = value.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ":", with: "")
        guard hash.count == sha1Length, hash.allSatisfy(\.isHexDigit) else { return nil }
        return hash.uppercased()
    }
}
