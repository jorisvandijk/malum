import Foundation

/// Every way Malum runs `defaults`, which reads and writes the preferences of apps through
/// macOS's preferences daemon, so a running app sees the change the way it would its own.
public enum Defaults {
    /// Where macOS keeps `defaults`.
    public static let path = "/usr/bin/defaults"

    /// Prints every preference in `domain` as a property list, an empty one when there's none.
    public static func export(_ domain: String) -> Command {
        Command(path, ["export", domain, "-"])
    }

    /// Sets the preference `key` in `domain` to `value`, a property list document, which keeps
    /// the value's type.
    public static func write(_ domain: String, _ key: String, _ value: String) -> Command {
        Command(path, ["write", domain, key, value])
    }

    /// Removes the preference `key` from `domain`, so the app falls back to its own default.
    public static func delete(_ domain: String, _ key: String) -> Command {
        Command(path, ["delete", domain, key])
    }

    /// The preferences in the output of `export`, or nil when it isn't a property list of them.
    static func preferences(in output: String) -> [String: Any]? {
        let list = try? PropertyListSerialization.propertyList(from: Data(output.utf8), format: nil)  // nil says it.
        return list as? [String: Any]
    }
}
