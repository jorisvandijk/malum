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
    /// Make the Mac match dots.
    case run
    /// Show what Malum manages and what doesn't match dots.
    case status
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
        case "init":
            self = Self.initialize(rest)
        case "disable":
            self = Self.disable(rest)
        default:
            guard let plain = Self.plain[first] else {
                self = .unknown(first)
                return
            }
            self = rest.first.map(Self.unknown) ?? plain
        }
    }

    /// The commands that take no arguments, by name.
    private static let plain: [String: Self] = [
        "reload": .reload, "safe": .safe, "permissions": .permissions, "run": .run, "status": .status,
    ]

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
