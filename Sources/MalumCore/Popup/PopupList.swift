/// The rows the popup shows for its query, and which one is selected. Kept apart from AppKit so
/// it's tested on Linux; the panel only draws it.
public struct PopupList<Row> {
    /// The rows that match the query, in order.
    public private(set) var rows: [Row] = []
    /// The selected row's place, nil when there are no rows.
    public private(set) var selection: Int?
    /// How many rows page up and page down move.
    private let pageSize: Int
    /// Whether cmd+backspace deletes the selected row.
    private let canDelete: Bool

    /// Creates an empty list that pages by `pageSize` rows, and deletes rows only when `canDelete`.
    public init(pageSize: Int, canDelete: Bool) {
        self.pageSize = max(pageSize, 1)
        self.canDelete = canDelete
    }

    /// The selected row.
    public var selected: Row? {
        guard let selection, rows.indices.contains(selection) else { return nil }
        return rows[selection]
    }

    /// Shows `rows` for a new query, with the first one selected.
    public mutating func show(_ rows: [Row]) {
        self.rows = rows
        selection = rows.isEmpty ? nil : 0
    }

    /// Selects the row at `index`, such as one the pointer clicked, when it's there.
    public mutating func select(_ index: Int) {
        guard rows.indices.contains(index) else { return }
        selection = index
    }

    /// Carries out `command`, and says what the popup does next.
    public mutating func handle(_ command: PopupCommand) -> PopupOutcome<Row> {
        switch command {
        case .down:
            move(by: 1)
        case .up:
            move(by: -1)
        case .pageDown:
            move(by: pageSize)
        case .pageUp:
            move(by: -pageSize)
        case .choose:
            return selected.map { .choose($0) } ?? .stay
        case .close:
            return .close
        case .switchList:
            return .switchList
        case .delete:
            return deleteSelected()
        }
        return .stay
    }

    /// Moves the selection by `step` rows, stopping at the first and last.
    private mutating func move(by step: Int) {
        guard let last = rows.indices.last else { return }
        selection = min(max((selection ?? 0) + step, 0), last)
    }

    /// Takes the selected row out and selects the one that took its place, or the new last.
    private mutating func deleteSelected() -> PopupOutcome<Row> {
        guard canDelete, let selection, let row = selected else { return .stay }
        rows.remove(at: selection)
        self.selection = rows.isEmpty ? nil : min(selection, rows.count - 1)
        return .delete(row)
    }
}
