/// What a key does in the popup. The panel turns keys into these; `PopupList` decides the rest.
public enum PopupCommand: Equatable, Sendable {
    /// Down or ctrl+n.
    case down
    /// Up or ctrl+p.
    case up
    /// Page down.
    case pageDown
    /// Page up.
    case pageUp
    /// Return, or a click on a row.
    case choose
    /// Escape.
    case close
    /// Tab, to the popup's other list.
    case switchList
    /// cmd+backspace, on a list whose rows can be deleted.
    case delete
}
