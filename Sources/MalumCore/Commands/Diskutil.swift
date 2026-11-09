/// Every way Malum runs `diskutil`, which asks macOS's disk service rather than the kernel, so it may
/// unmount a network share that `umount` isn't permitted to.
public enum Diskutil {
    /// Where macOS keeps `diskutil`.
    public static let path = "/usr/sbin/diskutil"

    /// Unmounts the volume at `volume` even when its server doesn't answer or a file on it is open, so
    /// nothing hangs on it.
    public static func forceUnmount(_ volume: String) -> Command {
        Command(path, ["unmount", "force", volume])
    }
}
