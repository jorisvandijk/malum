/// One of Malum's commands, such as `malum run`, opened in a new window of the terminal app that
/// `terminal` in `[system_config]` names, instead of in the popup. The window keeps a shell open
/// after the command ends, so its output stays to read.
public struct TerminalLaunch: Equatable, Sendable {
    /// The setting in `[system_config]` that names the terminal app by its bundle ID.
    public static let key = "terminal"
    /// The option terminal apps take for the program to run in the new window.
    private static let programOption = "-e"
    /// The shell's options: a login shell that runs the text after them.
    private static let shellOptions = ["-l", "-c"]

    /// The terminal app's bundle ID.
    public let bundleID: String
    /// What the terminal app is opened with.
    public let arguments: [String]

    /// Opens `executable` with `command`, such as `["run"]`, through `shell` in the terminal that
    /// `settings` names. Nil when `settings` names none, so the popup shows the output instead.
    public init?(settings: ConfigTable?, executable: String, command: [String], shell: String) {
        guard case .string(let bundleID)? = settings?[Self.key], AppBundle.isBundleID(bundleID) else { return nil }
        self.bundleID = bundleID
        let line = ([executable] + command).map(Escaping.shell).joined(separator: " ")
        let script = "\(line); exec \(Escaping.shell(shell)) \(Self.shellOptions[0])"
        arguments = [Self.programOption, shell] + Self.shellOptions + [script]
    }
}
