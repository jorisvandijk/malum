import Foundation

/// The clipboard history's list in the popup: every entry, newest first, or the best matches for
/// the search with the newest first among equals. Rows can be deleted.
@MainActor
final class ClipboardList: PopupSource {
    /// The history.
    let history: ClipHistory
    /// The time now, for each row's age.
    private let now: () -> Date
    /// What picking an entry does.
    private let onChoose: @MainActor (ClipEntry) -> Void
    /// What deleting an entry or all of them does, nil for all.
    private let onDelete: @MainActor (ClipEntry?) -> Void

    /// Creates the list of `history`.
    init(
        history: ClipHistory, now: @escaping () -> Date, onChoose: @escaping @MainActor (ClipEntry) -> Void,
        onDelete: @escaping @MainActor (ClipEntry?) -> Void
    ) {
        self.history = history
        self.now = now
        self.onChoose = onChoose
        self.onDelete = onDelete
    }

    /// Entries can be deleted, one or all.
    var canDelete: Bool { true }

    /// The entries matching `query` as rows.
    func rows(matching query: String) -> [PopupRow] {
        let entries = history.entries
        let shown =
            query.allSatisfy(\.isWhitespace)
            ? entries : FuzzyMatch.rank(entries, query: query, name: Self.searchText) { $0.date > $1.date }
        return shown.map(row)
    }

    /// Puts the entry picked back.
    func choose(_ row: PopupRow) {
        guard let entry = history.entries.first(where: { $0.id == row.id }) else { return }
        onChoose(entry)
    }

    /// Deletes the entry of `row`.
    func delete(_ row: PopupRow) {
        guard let entry = history.entries.first(where: { $0.id == row.id }) else { return }
        onDelete(entry)
    }

    /// Deletes every entry.
    func clear() {
        onDelete(nil)
    }

    /// The row for `entry`.
    private func row(_ entry: ClipEntry) -> PopupRow {
        let icon: PopupIcon
        switch entry.kind {
        case .text:
            icon = .none
        case .image:
            icon = .image(history.imagePath(of: entry))
        case .files:
            icon = (entry.paths?.first).map { .file($0) } ?? .none
        }
        return PopupRow(
            id: entry.id, title: Self.title(of: entry), detail: Self.age(since: entry.date, now: now()), icon: icon)
    }
}
