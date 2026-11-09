/// Why the key remaps couldn't be set or undone.
public enum KeyRemapError: Error, Equatable, Sendable {
    /// `hidutil` couldn't set the remaps, with why.
    case unset(reason: String)
    /// `hidutil` couldn't undo the remaps, with why.
    case uncleared(reason: String)
    /// The marker in the state folder couldn't be read or written.
    case marker(StateError)
}
