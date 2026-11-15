/// One of Malum's commands, such as `malum run`, opened in a new window or tab of the terminal app that
/// `terminal` in `[system_config]` names, instead of in the popup. The window keeps a shell open
/// after the command ends, so its output stays to read.
public struct TerminalLaunch: Equatable, Sendable {
    /// The setting in `[system_config]` that names the terminal app by its bundle ID.
    public static let key = "terminal"
    /// The option terminal apps take for the program to run in the new window.
    private static let programOption = "-e"
    /// The shell's option for a login shell, which reads the user's own setup.
    private static let loginOption = "-l"
    /// The shell's option that runs the text after it.
    private static let commandOption = "-c"

    /// The terminal app's bundle ID.
    public let bundleID: String
    /// What runs in the new window or tab: the shell with the command.
    public let program: [String]
    /// What the terminal app is opened with for a new window.
    public var arguments: [String] { [Self.programOption] + program }

    /// Opens `executable` with `command`, such as `["run"]`, through `shell` in the terminal that
    /// `settings` names. Nil when `settings` names none, so the popup shows the output instead.
    public init?(settings: ConfigTable?, executable: String, command: [String], shell: String) {
        guard case .string(let bundleID)? = settings?[Self.key], AppBundle.isBundleID(bundleID) else { return nil }
        self.bundleID = bundleID
        let line = ([executable] + command).map(Escaping.shell).joined(separator: " ")
        let script = "\(line); exec \(Escaping.shell(shell)) \(Self.loginOption)"
        program = [shell, Self.loginOption, Self.commandOption, script]
    }
}
