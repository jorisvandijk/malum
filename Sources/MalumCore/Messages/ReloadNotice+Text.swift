/// The words of the notification Reload in the menu shows.
extension ReloadNotice {
    /// The title when every module restarted.
    static var reloaded: String { "\(Project.name) reloaded" }

    /// The title when something went wrong.
    static var failed: String { "\(Project.name) couldn't reload everything" }

    /// How many modules run again.
    static func restarted(_ count: Int) -> String {
        count == 1 ? "1 module restarted" : "\(count) modules restarted"
    }

    /// The first problem, and how many more the log has.
    static func problem(_ text: String, more: Int) -> String {
        guard more > 0 else { return text }
        return "\(text) (and \(more) more in the log)"
    }
}
