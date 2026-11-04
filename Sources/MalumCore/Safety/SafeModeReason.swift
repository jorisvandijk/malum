/// Why Malum is in safe mode.
public enum SafeModeReason: String, Equatable, Sendable {
    /// Malum started too often in a short time, which looks like a crash at every start.
    case crashLoop = "crash loop"
    /// The user ran `malum safe`.
    case asked
}

// MARK: - CustomStringConvertible

extension SafeModeReason: CustomStringConvertible {
    /// The reason as the menu bar and the log say it.
    public var description: String {
        switch self {
        case .crashLoop:
            "\(Project.name) started \(LaunchRecord.limit) times within \(LaunchRecord.windowMinutes) minutes"
        case .asked:
            "turned on with \(Project.command) safe"
        }
    }
}
