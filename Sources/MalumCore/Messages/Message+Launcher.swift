/// The launcher's words.
extension Message {
    /// The launcher found `count` apps.
    static func foundApps(_ count: Int) -> Message {
        Message(.info, "found \(count) apps")
    }

    /// `app` has no bundle ID, so it can't be opened.
    static func noBundleID(_ app: String) -> Message {
        couldnt("open \(app)", "it has no bundle ID", level: .warn)
    }
}
