/// Every way Malum runs Homebrew's `brew`.
public enum Brew {
    /// Where Homebrew lives on Apple silicon.
    private static let prefix = "/opt/homebrew"
    /// Where Homebrew puts its commands.
    static let binFolder = "\(prefix)/bin"
    /// Where Homebrew puts what packages share, such as zsh plugins.
    static let shareFolder = "\(prefix)/share"
    /// Where Homebrew puts `brew`.
    public static let path = "\(binFolder)/brew"
    /// Seconds one install may take: a big cask downloads hundreds of megabytes.
    private static let installTimeoutSeconds = 1800

    /// Lists the installed packages of `kind`, one name per line.
    public static func installed(_ kind: PackageKind) -> Command {
        Command(path, ["list", kind.flag, "-1"])
    }

    /// Installs the package `name` of `kind`.
    public static func install(_ name: String, kind: PackageKind) -> Command {
        Command(path, ["install", kind.flag, name], timeoutSeconds: installTimeoutSeconds)
    }

    /// Uninstalls the package `name` of `kind`.
    public static func uninstall(_ name: String, kind: PackageKind) -> Command {
        Command(path, ["uninstall", kind.flag, name], timeoutSeconds: installTimeoutSeconds)
    }

    /// Whether the errors of a failed `uninstall` say other installed packages still need it.
    public static func isNeeded(_ errors: String) -> Bool {
        errors.contains("required by")
    }
}
