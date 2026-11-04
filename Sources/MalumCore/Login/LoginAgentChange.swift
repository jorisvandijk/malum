/// What starting Malum at login did when the app started.
public enum LoginAgentChange: Equatable, Sendable {
    /// The login agent was missing or different, and was written.
    case written
    /// The login agent was already there, byte for byte.
    case unchanged
    /// Malum runs from somewhere other than the installed app, such as a build folder, so it left
    /// the login agent alone.
    case notInstalled
}
