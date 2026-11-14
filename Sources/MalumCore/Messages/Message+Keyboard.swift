/// The words for what the keyboard module does while it runs, logged to track down a dropped hyper key.
extension Message {
    /// macOS told Malum about `change`.
    public static func keyboardChanged(_ change: KeyboardChange) -> Message {
        switch change {
        case .woke:
            Message(.info, "the Mac woke, setting the key remaps again")
        case .sessionActive:
            Message(.info, "switched back to this login, setting the key remaps again")
        case .keyboardAdded:
            Message(.info, "a keyboard was plugged in, setting the key remaps again")
        }
    }

    /// The event tap was started again, so it let go of any key held.
    static var tapRestarted: Message {
        Message(.info, "started the event tap again")
    }

    /// The key remaps were set again, with the event tap left running.
    static var remapsSetAgain: Message {
        Message(.info, "set the key remaps again")
    }
}
