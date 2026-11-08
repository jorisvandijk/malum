// MARK: - CustomStringConvertible

extension HotkeyClaim: CustomStringConvertible {
    /// The claim as a clash names it.
    var description: String {
        switch self {
        case .action(let name):
            name
        case .apps:
            "opening apps"
        case .key(let hotkey):
            hotkey.description
        }
    }
}
