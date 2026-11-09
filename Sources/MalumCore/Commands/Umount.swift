/// Every way Malum runs `umount`.
public enum Umount {
    /// Where macOS keeps `umount`.
    public static let path = "/sbin/umount"

    /// Unmounts the volume at `volume` even when its server doesn't answer, so nothing hangs on it.
    public static func force(_ volume: String) -> Command {
        Command(path, ["-f", volume])
    }
}
