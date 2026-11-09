/// What happened in the popup, as the panel passes it on to `PopupCenter`.
public enum PopupEvent: Equatable, Sendable {
    /// The search text changed.
    case query(String)
    /// A key with a meaning in the popup was pressed.
    case command(PopupCommand)
    /// The row at this place was clicked.
    case clicked(Int)
    /// The delete button of the row at this place was clicked.
    case deleteClicked(Int)
    /// Clear all was clicked, and confirmed with a second click.
    case clearAll
    /// The popup closed by itself, after a click elsewhere.
    case closed
}
