/// Where Malum stands with its own signature at start.
public enum SigningOutcome: Equatable, Sendable {
    /// The installed app is signed with Malum's certificate, so the modules may start.
    case signed
    /// The installed app was just signed, and has to start again to run as the signed app.
    case resigned
    /// Malum runs from somewhere other than the installed app, such as a build folder, so it
    /// isn't signed and the modules stay off.
    case notInstalled
    /// Signing failed, so the app that was there stays and the modules stay off.
    case failed(SigningError)
}
