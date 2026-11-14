/// The screenshots module's words.
extension Message {
    /// A shot was saved at `path`.
    static func savedScreenshot(_ path: String) -> Message {
        Message(.info, "saved \(private: path)")
    }

    /// The shot was saved but the clipboard didn't take it.
    static var couldntCopyScreenshot: Message {
        couldnt("put the screenshot on the clipboard", "macOS didn't take it", level: .warn)
    }
}
