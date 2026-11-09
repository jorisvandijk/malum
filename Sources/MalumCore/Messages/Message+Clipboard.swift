/// The clipboard history's words.
extension Message {
    /// A copy marked with `type` wasn't kept.
    static func skippedCopy(_ type: String) -> Message {
        Message(.info, "didn't keep a copy marked \(type)")
    }

    /// The entry couldn't go back on the clipboard.
    static var couldntPutBack: Message {
        couldnt("put the entry back on the clipboard", "macOS refused it")
    }
}

/// The clipboard history's degraded reason.
extension MessageText {
    /// Paste from Other Apps denies Malum the clipboard.
    static var clipboardDenied: MessageText {
        """
        System Settings > Privacy & Security > Paste from Other Apps denies \(Project.name) the clipboard, so \
        nothing is recorded; set it to allow
        """
    }
}
