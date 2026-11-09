/// Windows the window manager leaves alone: every window of an app, or only those whose title matches.
struct FloatRule: Equatable, Sendable {
    /// The app's bundle ID, such as `com.apple.systempreferences`.
    let app: String
    /// The pattern a window's title has to match, or nil for every window of the app.
    let title: String?

    /// Whether the rule matches a window titled `title` of the app `app`: every window of the app
    /// without a title pattern, only those whose title matches with one.
    func matches(app: String?, title: String?) -> Bool {
        guard app == self.app else { return false }
        guard let pattern = self.title else { return true }
        guard let title else { return false }
        guard let regex = try? Regex(pattern) else { return false }  // Checked when the settings were read.
        return title.contains(regex)
    }
}
