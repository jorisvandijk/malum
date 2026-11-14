/// Every way Malum runs `killall`, which quits a process by name. macOS starts Finder, the Dock
/// and the menu bar again by itself, which is how they pick up changed settings.
public enum Killall {
    /// Where macOS keeps `killall`.
    public static let path = "/usr/bin/killall"

    /// Quits every process called `process`, such as `Finder`.
    public static func restart(_ process: String) -> Command {
        Command(path, [process])
    }

    /// Whether `result` says no process had the name, so there was nothing to quit.
    public static func foundNothing(_ result: CommandResult) -> Bool {
        result.status == 1 && result.errors.contains(noMatch)
    }

    /// What `killall` writes when no process has the name.
    private static let noMatch = "No matching processes"

    /// Tells every process called `process` to read its settings again, such as `mDNSResponder`
    /// after a change to `/etc/hosts`.
    public static func hangUp(_ process: String) -> Command {
        Command(path, ["-HUP", process])
    }
}
