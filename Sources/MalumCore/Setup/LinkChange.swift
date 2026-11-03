/// What making the command link changed.
public enum LinkChange: Equatable, Sendable {
    /// There was no link, and now there is.
    case created
    /// The link already pointed at Malum.
    case unchanged
    /// The link pointed somewhere else and now points at Malum.
    case moved(from: String)
}
