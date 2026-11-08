/// Every way Malum runs `dscacheutil`, macOS's cache of names it looked up.
public enum DSCacheUtil {
    /// Where macOS keeps `dscacheutil`.
    public static let path = "/usr/bin/dscacheutil"

    /// Forgets every name looked up so far, so `/etc/hosts` is read again. Only root can run it.
    public static let flush = Command(path, ["-flushcache"])
}
