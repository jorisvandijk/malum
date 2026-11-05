/// A preference of an app, set by system config from the app's file in dots.
public struct AppPreference: Equatable, Sendable {
    /// The preferences domain, such as `com.if.Amphetamine`.
    public let domain: String
    /// The preference's name, as the app stores it.
    public let key: String
    /// The value, as a property list document.
    public let value: String
}
