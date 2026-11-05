import Foundation

/// Every way Malum runs `codium`, VSCodium's command line, which the `vscodium` cask links into
/// Homebrew's `bin`.
public enum Codium {
    /// Where the `vscodium` cask links `codium`.
    public static let path = "\(Brew.binFolder)/codium"
    /// Seconds one install may take, since it downloads the extension.
    private static let installTimeoutSeconds = 300

    /// Lists the installed extensions, one `publisher.name` per line.
    public static let installed = Command(path, ["--list-extensions"])

    /// Installs the extension `id` from Open VSX.
    public static func install(_ id: String) -> Command {
        Command(path, ["--install-extension", id], timeoutSeconds: installTimeoutSeconds)
    }

    /// Uninstalls the extension `id`.
    public static func uninstall(_ id: String) -> Command {
        Command(path, ["--uninstall-extension", id])
    }

    /// The extensions in the output of `installed`, in lowercase, since VSCodium ignores case.
    public static func ids(in output: String) -> Set<String> {
        Set(output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces).lowercased() })
    }

    /// Whether `id` names an extension as `publisher.name`.
    static func isExtensionID(_ id: String) -> Bool {
        let parts = id.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        return parts.count == ["publisher", "name"].count
            && parts.allSatisfy { part in
                !part.isEmpty && part.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0)) }
            }
    }
}
