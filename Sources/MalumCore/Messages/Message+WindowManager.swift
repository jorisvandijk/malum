/// The window manager's words.
extension Message {
    /// Hiding the other apps left `apps` in view.
    static func couldntHide(_ apps: [String]) -> Message {
        couldnt("hide \(apps.joined(separator: ", "))", "macOS didn't hide them", level: .warn)
    }
}
