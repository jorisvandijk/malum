/// Every way Malum runs `scutil`, which reads and changes this Mac's names.
public enum Scutil {
    /// One of the three names a Mac goes by.
    public enum Name: String, CaseIterable, Sendable {
        /// The name people see, such as in Finder's sidebar on other Macs and in AirDrop.
        case computerName = "ComputerName"
        /// The name the shell and network tools use.
        case hostName = "HostName"
        /// The name on the local network, as `<name>.local`.
        case localHostName = "LocalHostName"
    }

    /// Where macOS keeps `scutil`.
    public static let path = "/usr/sbin/scutil"

    /// Prints the name `name`. Fails when it isn't set.
    public static func get(_ name: Name) -> Command {
        Command(path, ["--get", name.rawValue])
    }

    /// Sets the name `name` to `value`. Only root can run it.
    public static func set(_ name: Name, to value: String) -> Command {
        Command(path, ["--set", name.rawValue, value])
    }
}
