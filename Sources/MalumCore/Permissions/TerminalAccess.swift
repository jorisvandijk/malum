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
            return Message(.info, "not running in a terminal, so there's no terminal to check")
        }
        switch check.state(of: .fullDiskAccess) {
        case .granted:
            return Message(.info, "\(terminal) has \(Permission.fullDiskAccess)")
        case .missing:
            let advice =
                "\(terminal) doesn't have \(Permission.fullDiskAccess), so macOS keeps asking \(terminal) about what "
                + "\(Project.command) does in it; turn it on in System Settings > Privacy & Security > "
                + "\(Permission.fullDiskAccess), then quit and reopen \(terminal)"
            return Message(.warn, MessageText(advice))
        case .unknown:
            return Message(.warn, "couldn't tell whether \(terminal) has \(Permission.fullDiskAccess)")
        }
    }
}
