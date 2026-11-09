/// Windows the window manager leaves alone: every window of an app, or only those whose title matches.
struct FloatRule: Equatable, Sendable {
    /// The app's bundle ID, such as `com.apple.systempreferences`.
    let app: String
    /// The pattern a window's title has to match, or nil for every window of the app.
    let title: String?
}
