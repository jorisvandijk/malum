/// The words of a web app's menus.
public enum WebAppWords {
    /// The Edit menu.
    public static let edit = "Edit"
    /// The View menu.
    public static let view = "View"
    /// Undoes the last edit.
    public static let undo = "Undo"
    /// Redoes the last undone edit.
    public static let redo = "Redo"
    /// Cuts the selection.
    public static let cut = "Cut"
    /// Copies the selection.
    public static let copy = "Copy"
    /// Pastes the clipboard.
    public static let paste = "Paste"
    /// Selects everything.
    public static let selectAll = "Select All"
    /// Loads the page again.
    public static let reload = "Reload"
    /// Goes to the page before.
    public static let back = "Back"
    /// Goes to the page after.
    public static let forward = "Forward"
    /// Closes the window.
    public static let close = "Close Window"

    /// Hides the web app called `name`.
    public static func hide(_ name: String) -> String {
        "Hide \(name)"
    }

    /// Quits the web app called `name`.
    public static func quit(_ name: String) -> String {
        "Quit \(name)"
    }
}
