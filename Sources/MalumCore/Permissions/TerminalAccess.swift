/// Checks that the terminal a command runs in has Full Disk Access.
///
/// A command run in a terminal counts as the terminal app, so macOS asks about the terminal, not
/// Malum, each time the command touches another app's data or a network volume. Full Disk Access
/// for the terminal covers all of it, and only the user can turn it on.
public struct TerminalAccess: Sendable {
    /// The terminal's name, or nil outside a terminal.
    private let terminal: String?
    /// Tells what the terminal has, since a command gets the terminal's permissions.
    private let check: any PermissionCheck

    /// Creates the check for `terminal`, the name `TerminalApp` gives, using `check`.
    public init(terminal: String?, check: any PermissionCheck) {
        self.terminal = terminal
        self.check = check
    }

    /// Whether the terminal is known to lack Full Disk Access, so System Settings should be opened.
    public var isMissing: Bool {
        terminal != nil && check.state(of: .fullDiskAccess) == .missing
    }

    /// What the check found, as a message.
    public func report() -> Message {
        guard let terminal else {
            return .noTerminal
        }
        switch check.state(of: .fullDiskAccess) {
        case .granted:
            return .hasFullDiskAccess(terminal)
        case .missing:
            return .lacksFullDiskAccess(terminal)
        case .unknown:
            return .unknownFullDiskAccess(terminal)
        }
    }
}
