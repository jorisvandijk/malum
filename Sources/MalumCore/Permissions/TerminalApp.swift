/// Names the terminal app a command runs in, from what the terminal puts in the environment.
public enum TerminalApp {
    /// What Apple's Terminal sets `TERM_PROGRAM` to.
    private static let appleTerminal = "Apple_Terminal"
    /// What iTerm sets `TERM_PROGRAM` to.
    private static let iTerm = "iTerm.app"
    /// What kitty sets `TERM` to.
    private static let kittyTerm = "xterm-kitty"
    /// The name used when the terminal doesn't say which one it is.
    private static let fallback = "your terminal app"

    /// The terminal's name as the user knows it, such as `kitty`, or nil when the command doesn't run
    /// in a terminal, as when a script pipes it.
    public static func name(environment: [String: String], isTerminal: Bool) -> String? {
        guard isTerminal else { return nil }
        if environment["KITTY_WINDOW_ID"] != nil || environment["TERM"] == kittyTerm {
            return "kitty"
        }
        switch environment["TERM_PROGRAM", default: ""] {
        case appleTerminal:
            return "Terminal"
        case iTerm:
            return "iTerm"
        case "":
            return fallback
        case let program:
            return program
        }
    }
}
