/// Everything the popup shows at one moment.
public struct PopupContent: Equatable, Sendable {
    /// The search field's grey text while it's empty, such as "Search apps".
    public let placeholder: String
    /// The list's name, shown at the top right.
    public let label: String
    /// The rows, in order.
    public let rows: [PopupRow]
    /// The selected row's place, nil when there are none.
    public let selection: Int?
    /// Whether rows can be deleted, and the whole list cleared.
    public let canDelete: Bool

    /// Nothing to show, before the popup first opens.
    public static let empty = PopupContent(placeholder: "", label: "", rows: [], selection: nil, canDelete: false)
}
