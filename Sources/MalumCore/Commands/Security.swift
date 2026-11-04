/// Every way Malum runs `security`.
public enum Security {
    /// The tool.
    private static let path = "/usr/bin/security"
    /// The length of a certificate's SHA-1, in hex.
    private static let hashLength = 40

    /// Lists the certificates the keychains hold for code signing. Without `-v`, since a
    /// self-signed certificate isn't trusted, but codesign signs with it all the same.
    public static func findIdentities() -> Command {
        Command(path, ["find-identity", "-p", "codesigning"])
    }

    /// Adds the certificate and key in the PKCS #12 file `file`, protected with `password`, to
    /// `keychain`. `-T` lets codesign use the key without asking.
    public static func importIdentity(_ file: String, password: String, keychain: String) -> Command {
        Command(path, ["import", file, "-k", keychain, "-f", "pkcs12", "-P", password, "-T", "/usr/bin/codesign"])
    }

    /// The SHA-1 of the certificate called `name` in the output of `findIdentities`, whose lines
    /// look like `  1) 3F2A…9C "Malum code signing" (CSSMERR_TP_NOT_TRUSTED)`. Nil when it isn't there.
    public static func identity(named name: String, in output: String) -> String? {
        let quoted = "\"\(name)\""
        let line = output.split(separator: "\n").first { $0.contains(quoted) }
        let hash = line?.split(separator: " ").first { $0.count == hashLength && $0.allSatisfy(\.isHexDigit) }
        return hash.map { String($0) }
    }
}
