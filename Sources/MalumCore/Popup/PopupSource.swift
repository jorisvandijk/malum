/// A list the popup can show, such as the launcher's apps or the clipboard history. A module
/// gives one to `PopupCenter.register`.
@MainActor
public protocol PopupSource: AnyObject {
    /// The list's name, shown at the top right.
    var label: String { get }
    /// The search field's grey text while it's empty.
    var placeholder: String { get }
    /// Whether rows can be deleted and the list cleared.
    var canDelete: Bool { get }
    /// The rows matching `query`, best first, or every row for an empty one.
    func rows(matching query: String) -> [PopupRow]
    /// Does what picking `row` means, after the popup has closed.
    func choose(_ row: PopupRow)
    /// Deletes `row`.
    func delete(_ row: PopupRow)
    /// Deletes every row.
    func clear()
}

// MARK: - Defaults

extension PopupSource {
    /// Rows can't be deleted unless a list says so.
    public var canDelete: Bool { false }

    /// Does nothing, for a list whose rows can't be deleted.
    public func delete(_ row: PopupRow) {
        // Nothing to delete.
    }

    /// Does nothing, for a list that can't be cleared.
    public func clear() {
        // Nothing to clear.
    }
}
