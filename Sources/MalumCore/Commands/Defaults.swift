import Foundation

/// Every way Malum runs `defaults`, which reads and writes the preferences of apps through
/// macOS's preferences daemon, so a running app sees the change the way it would its own.
public enum Defaults {
    /// Where macOS keeps `defaults`.
    public static let path = "/usr/bin/defaults"
    /// What a system-wide domain's file has after its name.
    public static let fileExtension = ".plist"
    /// What a domain's name ends with when it's the version macOS keeps for this Mac only.
    private static let currentHostSuffix = " (current host)"

    /// The version of `domain` macOS keeps for this Mac only, which `defaults -currentHost` reads,
    /// such as the menu bar's items in `com.apple.controlcenter`.
    public static func currentHost(_ domain: String) -> String {
        domain + currentHostSuffix
    }

    /// Whether `domain` is a system-wide one, named by its file without `.plist`, such as
    /// `/Library/Preferences/net.librewolf.librewolf`. Only root can change those.
    public static func isSystemWide(_ domain: String) -> Bool {
        domain.hasPrefix("/Library/")
    }

    /// Prints every preference in `domain` as a property list, an empty one when there's none.
    public static func export(_ domain: String) -> Command {
        Command(path, target(domain) + ["export", name(of: domain), "-"])
    }

    /// Sets the preference `key` in `domain` to `value`, a property list document, which keeps
    /// the value's type.
    public static func write(_ domain: String, _ key: String, _ value: String) -> Command {
        Command(path, target(domain) + ["write", name(of: domain), key, value])
    }

    /// Prints the value of `key` in the property list at `file`, given without `.plist`, such as an
    /// app's `Contents/Info`.
    public static func read(_ file: String, _ key: String) -> Command {
        Command(path, ["read", file, key])
    }

    /// Removes the preference `key` from `domain`, so the app falls back to its own default.
    public static func delete(_ domain: String, _ key: String) -> Command {
        Command(path, target(domain) + ["delete", name(of: domain), key])
    }

    /// `-currentHost` when `domain` is the version for this Mac only, otherwise nothing.
    private static func target(_ domain: String) -> [String] {
        domain.hasSuffix(currentHostSuffix) ? ["-currentHost"] : []
    }

    /// The name `defaults` knows `domain` by.
    private static func name(of domain: String) -> String {
        domain.hasSuffix(currentHostSuffix) ? String(domain.dropLast(currentHostSuffix.count)) : domain
    }

    /// The preferences in the output of `export`, or nil when it isn't a property list of them.
    static func preferences(in output: String) -> [String: Any]? {
        let list = try? PropertyListSerialization.propertyList(from: Data(output.utf8), format: nil)  // nil says it.
        return list as? [String: Any]
    }
}
