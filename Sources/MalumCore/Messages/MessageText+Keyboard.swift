/// The words for what keeps the keyboard module's keys from working.
extension MessageText {
    /// Secure input is on in `app`, or in an app macOS doesn't name.
    static func secureInput(in app: String?) -> MessageText {
        let holder = app.map { " in \($0)" } ?? ""
        return "secure input is on\(holder), so no shortcut works until it's off"
    }

    /// Modifier Keys in System Settings turns `key`, the hyper key, into another key on a keyboard.
    static func hyperKeySwapped(_ key: Key) -> MessageText {
        """
        System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys changes \(key.name) on a keyboard, so \
        the hyper key doesn't work there; set \(key.name) back to itself
        """
    }
}
