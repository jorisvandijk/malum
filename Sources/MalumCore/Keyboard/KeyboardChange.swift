/// Something after which macOS may have dropped the key remaps.
public enum KeyboardChange: Sendable {
    /// The Mac woke from sleep.
    case woke
    /// The user switched back to this login.
    case sessionActive
    /// A keyboard was plugged in or reconnected.
    case keyboardAdded
}
