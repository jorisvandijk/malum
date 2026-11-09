/// Every way Malum runs `hidutil`, which sets the key remaps of every keyboard for this login.
public enum Hidutil {
    /// Where macOS keeps `hidutil`.
    public static let path = "/usr/bin/hidutil"

    /// Replaces the whole key mapping with `mapping`. macOS keeps one list, so this also undoes
    /// whatever was set before.
    static func set(_ mapping: KeyMapping) -> Command {
        Command(path, ["property", "--set", mapping.json])
    }
}
