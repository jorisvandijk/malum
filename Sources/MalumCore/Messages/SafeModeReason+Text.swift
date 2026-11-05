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
