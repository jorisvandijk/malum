/// What the command line asked Malum to do.
public enum Invocation: Equatable, Sendable {
    /// Show the version.
    case version
    /// Show how to use the command.
    case help
    /// Record where dots is and link the command, with the path to dots as given.
    case initialize(dots: String)
    /// Ask the running app to reload.
    case reload
    /// Turn safe mode on.
    case safe
    /// Keep a module off, by its id.
    case disable(module: String)
    /// Check that the terminal has the permissions Malum needs in it.
    case permissions
    /// Make the Mac match dots and update Malum, installing an older release too when `force` is set.
    case run(force: Bool)
    /// Put back the version of Malum the last update replaced.
    case rollback
    /// Show what Malum manages and what doesn't match dots.
    case status
    /// Ask for the GitHub token and keep it in the keychain, or remove it when `remove` is set.
    case token(remove: Bool)
    /// Ask for the password of the Samba server called `server` and keep it in the keychain.
    case sambaPassword(server: String)
    /// Show Malum's log as it comes in, or the `last` stretch of it, such as `1h`.
    case log(last: String?)
    /// Ask the running app to run a module's action, by the action's name.
    case action(String)
    /// A command that's missing an argument, with what it needs.
    case incomplete(command: String, needs: String)
    /// An argument Malum doesn't know.
    case unknown(String)

    /// Reads the arguments that follow the executable's path.
    public init(arguments: [String]) {
        guard let first = arguments.first else {
            self = .help
            return
        }
        let rest = Array(arguments.dropFirst())
        switch first {
        case "--version", "-v":
            self = .version
        case "--help", "-h":
            self = .help
        default:
            self = Self.withArguments[first].map { $0(rest) } ?? Self.plainCommand(first, rest)
        }
    }

    /// The command `name` that takes no arguments, unknown when it isn't one or `rest` holds any.
    private static func plainCommand(_ name: String, _ rest: [String]) -> Self {
        guard let plain = plain[name] else { return .unknown(name) }
        return rest.first.map(Self.unknown) ?? plain
    }

    /// The commands that read their own arguments, by name.
    private static let withArguments: [String: @Sendable ([String]) -> Self] = [
        "init": initialize, "disable": disable, "token": token, runName: run, "samba": samba, logName: log,
    ]

    /// The commands that take no arguments, by name.
    private static let plain: [String: Self] = [
        "reload": .reload, "safe": .safe, "permissions": .permissions, "status": .status, "rollback": .rollback,
    ]

    /// Reads the arguments of `disable`: exactly one module.
    private static func disable(_ arguments: [String]) -> Self {
        guard let module = arguments.first else { return .incomplete(command: "disable", needs: needsModule) }
        guard let extra = arguments.dropFirst().first else { return .disable(module: module) }
        return .unknown(extra)
    }

    /// Reads the arguments of `token`: none, or `--remove`. The token itself is never an argument,
    /// so it can't end up in the shell's history.
    private static func token(_ arguments: [String]) -> Self {
        guard let first = arguments.first else { return .token(remove: false) }
        guard first == "--remove" else { return .unknown(first) }
        return arguments.dropFirst().first.map(Self.unknown) ?? .token(remove: true)
    }

    /// Reads the arguments of `samba`: `password` and one server. The password itself is never an
    /// argument.
    private static func samba(_ arguments: [String]) -> Self {
        guard let first = arguments.first else { return .incomplete(command: "samba", needs: needsSambaCommand) }
        guard first == "password" else { return .unknown(first) }
        let rest = arguments.dropFirst()
        guard let server = rest.first else { return .incomplete(command: "samba password", needs: needsServer) }
        return rest.dropFirst().first.map(Self.unknown) ?? .sambaPassword(server: server)
    }

    /// Reads the arguments of `run`: nothing, or `--force`.
    private static func run(_ arguments: [String]) -> Self {
        guard let first = arguments.first else { return .run(force: false) }
        guard first == forceFlag else { return .unknown(first) }
        return arguments.dropFirst().first.map(Self.unknown) ?? .run(force: true)
    }

    /// Reads the arguments of `log`: nothing, or `--last` and a stretch of time.
    private static func log(_ arguments: [String]) -> Self {
        guard let first = arguments.first else { return .log(last: nil) }
        guard first == lastFlag else { return .unknown(first) }
        let rest = arguments.dropFirst()
        guard let stretch = rest.first else { return .incomplete(command: "log \(lastFlag)", needs: needsStretch) }
        guard UnifiedLog.isStretch(stretch) else { return .unknown(stretch) }
        return rest.dropFirst().first.map(Self.unknown) ?? .log(last: stretch)
    }

    /// The name of `run`.
    private static let runName = "run"
    /// The name of `log`.
    private static let logName = "log"

    /// The arguments of `run` without a password asked or a release forced: what Run in the menu
    /// opens in the terminal.
    public static let runArguments = [runName]

    /// The arguments of `log` for the `last` stretch of time, such as `1h`.
    public static func logArguments(last: String) -> [String] {
        [logName, lastFlag, last]
    }

    /// The flag that makes `log` show a stretch of time.
    private static let lastFlag = "--last"

    /// The flag that lets `run` install an older release.
    private static let forceFlag = "--force"

    /// Reads the arguments of `init`: exactly one path.
    private static func initialize(_ arguments: [String]) -> Self {
        guard let dots = arguments.first else { return .incomplete(command: "init", needs: needsDots) }
        guard let extra = arguments.dropFirst().first else { return .initialize(dots: dots) }
        return .unknown(extra)
    }
}
