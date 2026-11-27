/// The words for `[screen_lock]` in `macos.toml`.
extension MessageText {
    /// Changing how soon the password is asked once the screen goes black.
    static let changeScreenLock: MessageText = "change when the screen asks for your password"
}

extension Message {
    /// The password is asked `seconds` after the screen goes black now, set from `macos.toml`.
    static func screenLockSet(after seconds: Int) -> Message {
        let delay: MessageText = seconds == 0 ? "as soon as" : "\(seconds) seconds after"
        return Message(
            .info, "the screen asks for your password \(delay) it goes black now, from \(Paths.macOSTOMLName)")
    }

    /// The screen lock couldn't be changed.
    static var screenLockNotSet: Message {
        couldnt(.changeScreenLock, "macOS didn't take it, check the password")
    }
}
