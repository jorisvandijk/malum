import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct PopupCenterTests {
    private let popup = FakePopup()
    private let apps = FakePopupSource("Apps", names: ["Mail", "Maps", "Safari"])
    private let history = FakePopupSource("History", names: ["one", "two"], canDelete: true)

    private func center() -> PopupCenter {
        let center = PopupCenter(popup: popup)
        center.register(apps, as: "launcher")
        center.register(history, as: "clipboard")
        return center
    }

    private var titles: [String] {
        popup.shown.last?.rows.map(\.title) ?? []
    }

    @Test func toggleOpensOnTheListWithEveryRow() {
        let center = center()
        center.toggle("launcher")
        #expect(popup.isOpen)
        #expect(popup.shown.last?.label == "Apps")
        #expect(titles == ["Mail", "Maps", "Safari"])
        #expect(popup.shown.last?.selection == 0)
    }

    @Test func toggleAgainCloses() {
        let center = center()
        center.toggle("launcher")
        center.toggle("launcher")
        #expect(!popup.isOpen)
    }

    @Test func otherListsKeyMovesToItWhileOpen() {
        let center = center()
        center.toggle("launcher")
        center.toggle("clipboard")
        #expect(popup.isOpen)
        #expect(popup.opened == 1)
        #expect(popup.shown.last?.label == "History")
    }

    @Test func unknownListDoesNothing() {
        center().toggle("screenshots")
        #expect(!popup.isOpen)
    }

    @Test func typingSearches() {
        let center = center()
        center.toggle("launcher")
        popup.send(.query("saf"))
        #expect(titles == ["Safari"])
    }

    @Test func tabKeepsTheSearch() {
        let center = center()
        center.toggle("launcher")
        popup.send(.query("o"))
        popup.send(.command(.switchList))
        #expect(popup.shown.last?.label == "History")
        #expect(titles == ["one", "two"])
        popup.send(.command(.switchList))
        #expect(popup.shown.last?.label == "Apps")
    }

    @Test func returnClosesAndChoosesTheSelectedRow() {
        let center = center()
        center.toggle("launcher")
        popup.send(.command(.down))
        popup.send(.command(.choose))
        #expect(!popup.isOpen)
        #expect(apps.chosen == ["Maps"])
    }

    @Test func clickChoosesThatRow() {
        let center = center()
        center.toggle("launcher")
        popup.send(.clicked(2))
        #expect(apps.chosen == ["Safari"])
    }

    @Test func escapeCloses() {
        let center = center()
        center.toggle("launcher")
        popup.send(.command(.close))
        #expect(!popup.isOpen)
        #expect(apps.chosen.isEmpty)
    }

    @Test func deleteWorksOnlyWhereRowsCanBeDeleted() {
        let center = center()
        center.toggle("launcher")
        popup.send(.command(.delete))
        #expect(titles.count == 3)
        center.toggle("clipboard")
        popup.send(.deleteClicked(1))
        #expect(history.deleted == ["two"])
        #expect(titles == ["one"])
    }

    @Test func clearAllEmptiesTheList() {
        let center = center()
        center.toggle("clipboard")
        popup.send(.clearAll)
        #expect(titles.isEmpty)
        #expect(popup.shown.last?.selection == nil)
    }

    @Test func refreshShowsNewRowsOnlyForTheListShown() {
        let center = center()
        center.toggle("launcher")
        let shown = popup.shown.count
        center.refresh("clipboard")
        #expect(popup.shown.count == shown)
        apps.names.append("Notes")
        center.refresh("launcher")
        #expect(titles.contains("Notes"))
    }

    @Test func unregisteringTheListShownCloses() {
        let center = center()
        center.toggle("clipboard")
        center.unregister("clipboard")
        #expect(!popup.isOpen)
        center.toggle("clipboard")
        #expect(!popup.isOpen)
    }

    @Test func openingAgainStartsWithAnEmptySearch() {
        let center = center()
        center.toggle("launcher")
        popup.send(.query("saf"))
        center.toggle("launcher")
        center.toggle("launcher")
        #expect(titles.count == 3)
    }
}
