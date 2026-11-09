/// One row of the popup, as a list gives it.
public struct PopupRow: Equatable, Sendable {
    /// Tells the row apart from the others in its list, such as an app's path.
    public let id: String
    /// The text the row shows and the search matches.
    public let title: String
    /// Short text on the right, such as how long ago something was copied.
    public let detail: String?
    /// The picture in front.
    public let icon: PopupIcon

    /// Creates a row.
    public init(id: String, title: String, detail: String? = nil, icon: PopupIcon = .none) {
        self.id = id
        self.title = title
        self.detail = detail
        self.icon = icon
    }
}
