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
    /// A command that's missing an argument, with what it needs.
    case incomplete(command: String, needs: String)
    /// An argument Malum doesn't know.
    case unknown(String)

    /// The help text.
    public static let usage = """
        usage: \(Project.command) [--version | --help]
               \(Project.command) init <path to dots>
               \(Project.command) reload
               \(Project.command) safe
               \(Project.command) disable <module>
               \(Project.command) permissions

          init         record where dots is checked out and link ~/.local/bin/\(Project.command)
          reload       ask the running app to reload
          safe         keep every module off until you leave safe mode from the menu bar
          disable      keep one module off until you enable it from the menu bar
          permissions  check that this terminal has Full Disk Access
          --version    show the version
          --help       show this help
        """

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
        case "init":
            self = Self.initialize(rest)
        case "reload":
            self = rest.first.map(Self.unknown) ?? .reload
        case "safe":
            self = rest.first.map(Self.unknown) ?? .safe
        case "disable":
            self = Self.disable(rest)
        case "permissions":
            self = rest.first.map(Self.unknown) ?? .permissions
        default:
            self = .unknown(first)
        }
    }

    /// Reads the arguments of `disable`: exactly one module.
    private static func disable(_ arguments: [String]) -> Self {
        guard let module = arguments.first else { return .incomplete(command: "disable", needs: "a module") }
        guard let extra = arguments.dropFirst().first else { return .disable(module: module) }
        return .unknown(extra)
    }

    /// Reads the arguments of `init`: exactly one path.
    private static func initialize(_ arguments: [String]) -> Self {
        guard let dots = arguments.first else { return .incomplete(command: "init", needs: "the path to dots") }
        guard let extra = arguments.dropFirst().first else { return .initialize(dots: dots) }
        return .unknown(extra)
    }
}
