/// The preferences Malum set in one domain, as the record of what Malum installed keeps them.
public struct ManagedPreferences: Codable, Equatable, Sendable {
    /// The app whose file in `apps/` they're set from.
    public let app: String
    /// The preferences' names.
    public let keys: [String]
}
