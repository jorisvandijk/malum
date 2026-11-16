import Foundation

/// Every way Malum runs `security`.
public enum Security {
    /// The tool.
    private static let path = "/usr/bin/security"
    /// The length of a certificate's SHA-1, in hex.
    private static let hashLength = 40
    /// The partitions of Apple's own tools and apps, which codesign belongs to.
    private static let appleTools = "apple-tool:,apple:"
    /// Seconds to wait for the keychain's password.
    private static let passwordTimeoutSeconds = 300

    /// Lists the certificates the keychains hold for code signing. Without `-v`, since a
    /// self-signed certificate isn't trusted, but codesign signs with it all the same.
    public static func findIdentities() -> Command {
        Command(path, ["find-identity", "-p", "codesigning"])
    }

    /// Adds the certificate and key in the PKCS #12 file `file`, protected with `password`, to
    /// `keychain`. `-T` lets codesign use the key without asking.
    public static func importIdentity(_ file: String, password: String, keychain: String) -> Command {
        Command(path, ["import", file, "-k", keychain, "-f", "pkcs12", "-P", password, "-T", Codesign.path])
    }

    /// Lets Apple's own tools, codesign among them, use the private key called `label` in
    /// `keychain` without asking. Asks for the keychain's password on the terminal.
    public static func allowAppleTools(key label: String, keychain: String) -> Command {
        Command(
            path, ["set-key-partition-list", "-S", appleTools, "-s", "-l", label, keychain],
            timeoutSeconds: passwordTimeoutSeconds, onTerminal: true)
    }

    /// What `security` exits with when the keychain has no such item.
    public static let notFoundStatus: Int32 = 44

    /// Prints the generic password with `service` and `account`. An item `security` made itself
    /// reads without the keychain asking, whichever build of Malum runs this.
    public static func findPassword(service: String, account: String) -> Command {
        Command(path, ["find-generic-password", "-s", service, "-a", account, "-w"])
    }

    /// Looks the generic password with `service` and `account` up, without its data.
    public static func findItem(service: String, account: String) -> Command {
        Command(path, ["find-generic-password", "-s", service, "-a", account])
    }

    /// Deletes the generic password with `service` and `account`.
    public static func deletePassword(service: String, account: String) -> Command {
        Command(path, ["delete-generic-password", "-s", service, "-a", account])
    }

    /// Adds the generic password `password` with `service` and `account`, or replaces its data.
    /// The password goes in on stdin, in hex, so it never shows up in the arguments.
    public static func savePassword(_ password: String, service: String, account: String) -> Command {
        let hex = Data(password.utf8).map { String(format: "%02x", $0) }.joined()
        let line = "add-generic-password -U -s \(service) -a \(account) -X \(hex)\n"
        return Command(path, ["-i"], input: line)
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
