/// Every way Malum runs kitty's `kitten`, which controls a running kitty through the socket that
/// `allow_remote_control socket-only` and `listen_on unix:/tmp/kitty` in kitty.conf open.
public enum Kitten {
    /// kitty's bundle ID.
    public static let bundleID = "net.kovidgoyal.kitty"
    /// Where kitty keeps `kitten`, inside its app bundle.
    private static let bundlePath = "Contents/MacOS/kitten"
    /// The socket's path before the process ID, which kitty adds to `listen_on` itself.
    private static let socketPrefix = "/tmp/kitty-"
    /// What `kitten @ --to` takes before a socket's path.
    private static let socketScheme = "unix:"

    /// The socket of the kitty with `processID`, which is there only while it listens.
    public static func socket(processID: Int32) -> String {
        "\(socketPrefix)\(processID)"
    }

    /// Opens a new tab running `program` in the kitty at `app` that listens on `socket`.
    public static func newTab(app: String, socket: String, program: [String]) -> Command {
        Command("\(app)/\(bundlePath)", ["@", "--to", socketScheme + socket, "launch", "--type=tab"] + program)
    }
}
