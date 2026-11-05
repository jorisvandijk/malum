/// Why Malum is in safe mode.
public enum SafeModeReason: String, Equatable, Sendable {
    /// Malum started too often in a short time, which looks like a crash at every start.
    case crashLoop = "crash loop"
    /// The user ran `malum safe`.
    case asked
}
