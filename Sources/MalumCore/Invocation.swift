/// What the command line asked Malum to do.
public enum Invocation: Equatable, Sendable {
    /// Show the version.
    case version
    /// Show how to use the command.
    case help
    /// An argument Malum doesn't know.
    case unknown(String)

    /// The help text.
    public static let usage = """
        usage: \(Project.command) [--version | --help]

          --version  show the version
          --help     show this help
        """

    /// Reads the arguments that follow the executable's path.
    public init(arguments: [String]) {
        guard let first = arguments.first else {
            self = .help
            return
        }
        switch first {
        case "--version", "-v":
            self = .version
        case "--help", "-h":
            self = .help
        default:
            self = .unknown(first)
        }
    }
}
