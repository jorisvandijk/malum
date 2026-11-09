/// What the popup does after a `PopupCommand`, beyond moving the selection.
public enum PopupOutcome<Row> {
    /// Nothing more: the selection moved, or the key did nothing.
    case stay
    /// Runs the chosen row and closes.
    case choose(Row)
    /// Closes.
    case close
    /// Shows the other list, keeping the query.
    case switchList
    /// Deletes the row, which is already out of the list.
    case delete(Row)
}
