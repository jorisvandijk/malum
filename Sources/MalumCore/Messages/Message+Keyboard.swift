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

    /// `reason`, such as secure input, keeps keys from reaching Malum.
    static func keysBlocked(_ reason: MessageText) -> Message {
        Message(.warn, reason)
    }

    /// What kept keys from reaching Malum has ended.
    static var keysReachMalumAgain: Message {
        Message(.info, "keys reach Malum again")
    }

    /// macOS switched the event tap off `times` times since the last check, and it was switched
    /// straight back on.
    static func tapSwitchedOffByMacOS(times: Int) -> Message {
        Message(.info, "macOS switched the event tap off (\(times) since the last check), switched it back on")
    }
}
