/// A power setting Malum set, as the record of what Malum installed keeps it.
public struct ManagedPower: Codable, Equatable, Sendable {
    /// What Malum set it to.
    public let value: Int
    /// What it was before Malum first set it, which it goes back to when `macos.toml` drops it.
    public let original: Int
}
