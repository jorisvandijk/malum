/// Every way Malum runs `sudo`. These all run on the terminal, where sudo remembers the password.
public enum Sudo {
    /// Where macOS keeps `sudo`.
    public static let path = "/usr/bin/sudo"
    /// Seconds to wait for the password.
    private static let promptTimeoutSeconds = 300

    /// Asks for the password, or Touch ID when sudo is set up for it, so later runs don't ask.
    public static let authorize = Command(
        path, ["-v", "-p", "[sudo] password for %u: "], timeoutSeconds: promptTimeoutSeconds, onTerminal: true)

    /// Keeps the password remembered a while longer, without asking for it.
    public static let refresh = Command(path, ["-n", "-v"], onTerminal: true)

    /// Runs `command` as root, failing instead of asking when the password isn't remembered.
    public static func asRoot(_ command: Command) -> Command {
        Command(
            path, ["-n", command.executable] + command.arguments, timeoutSeconds: command.timeoutSeconds,
            onTerminal: true)
    }
}
