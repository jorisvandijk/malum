/// Every way Malum runs `sysadminctl`, which reads and changes how soon the Mac asks for the
/// password once the screen goes black. macOS ignores the old screensaver preferences for this.
public enum Sysadminctl {
    /// How soon the password is asked once the screen goes black.
    public enum ScreenLock: Equatable, Sendable {
        /// After this many seconds, 0 for right away.
        case after(Int)
        /// Never.
        case off
    }

    /// Where macOS keeps `sysadminctl`.
    public static let path = "/usr/sbin/sysadminctl"
    /// The flag that reads or changes the screen lock.
    private static let screenLockFlag = "-screenLock"
    /// The words in the output of `screenLockStatus` before the delay.
    private static let delayWords = "screenLock delay is "
    /// The words in the output of `screenLockStatus` when it's off.
    private static let offWords = "screenLock is off"
    /// The delay `sysadminctl` takes and prints for right away.
    private static let immediate = "immediate"
    /// Seconds to wait for the password.
    private static let promptTimeoutSeconds = 300

    /// Prints how soon the password is asked, to stderr.
    public static let screenLockStatus = Command(path, [screenLockFlag, "status"])

    /// Asks for the password `seconds` after the screen goes black, right away at 0. It runs on the
    /// terminal, since it asks for the user's own password there.
    public static func setScreenLock(after seconds: Int) -> Command {
        let delay = seconds == 0 ? immediate : String(seconds)
        return Command(
            path, [screenLockFlag, delay, "-password", "-"], timeoutSeconds: promptTimeoutSeconds, onTerminal: true)
    }

    /// The screen lock in the output of `screenLockStatus`, or nil when it doesn't say.
    static func screenLock(in output: String) -> ScreenLock? {
        guard !output.contains(offWords) else { return .off }
        guard let range = output.range(of: delayWords) else { return nil }
        let delay = output[range.upperBound...].prefix { !$0.isWhitespace }
        guard delay != immediate else { return .after(0) }
        return Int(delay).map { .after($0) }
    }
}
