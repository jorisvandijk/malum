// MARK: - CustomStringConvertible

/// The words for why a window floats.
extension FloatReason: CustomStringConvertible {
    /// The reason as the log says it.
    var description: String {
        switch self {
        case .rule:
            "a float rule matches it"
        case .role(let role):
            "it's a \(role), not a window"
        case .subrole(let subrole):
            "it's a \(subrole)"
        case .fullScreen:
            "it's in fullscreen"
        case .modal:
            "it's modal"
        case .fixedSize:
            "it can't be resized"
        }
    }
}
