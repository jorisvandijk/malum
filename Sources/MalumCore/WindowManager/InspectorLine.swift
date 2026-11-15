/// One line the window inspector shows, such as the app's name.
public struct InspectorLine: Equatable, Sendable {
    /// What the line is about, such as `bundle id`.
    public let label: String
    /// What the window says.
    public let value: String
}
