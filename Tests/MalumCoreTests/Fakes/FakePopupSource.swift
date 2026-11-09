@testable import MalumCore

/// A popup list of fixed names, keeping what was chosen and deleted.
@MainActor
final class FakePopupSource: PopupSource {
    let label: String
    let placeholder = "Search"
    let canDelete: Bool
    var names: [String]
    var chosen: [String] = []
    var deleted: [String] = []

    init(_ label: String, names: [String], canDelete: Bool = false) {
        self.label = label
        self.names = names
        self.canDelete = canDelete
    }

    func rows(matching query: String) -> [PopupRow] {
        FuzzyMatch.rank(names, query: query, name: { $0 }, ties: { $0 < $1 }).map { PopupRow(id: $0, title: $0) }
    }

    func choose(_ row: PopupRow) {
        chosen.append(row.id)
    }

    func delete(_ row: PopupRow) {
        deleted.append(row.id)
        names.removeAll { $0 == row.id }
    }

    func clear() {
        names = []
    }
}
