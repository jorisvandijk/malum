import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct PopupListTests {
    private func list(_ rows: [String] = ["a", "b", "c", "d"], canDelete: Bool = true) -> PopupList<String> {
        var list = PopupList<String>(pageSize: 2, canDelete: canDelete)
        list.show(rows)
        return list
    }

    @Test func showSelectsTheFirstRow() {
        #expect(list().selected == "a")
    }

    @Test func noRowsSelectsNothing() {
        let empty = list([])
        #expect(empty.selection == nil)
        #expect(empty.selected == nil)
    }

    @Test func downAndUpMoveOneRowAndStopAtTheEnds() {
        var list = list()
        _ = list.handle(.up)
        #expect(list.selected == "a")
        for _ in 0..<5 { _ = list.handle(.down) }
        #expect(list.selected == "d")
        _ = list.handle(.up)
        #expect(list.selected == "c")
    }

    @Test func pagesMoveByThePageSize() {
        var list = list()
        _ = list.handle(.pageDown)
        #expect(list.selected == "c")
        _ = list.handle(.pageUp)
        #expect(list.selected == "a")
    }

    @Test func chooseGivesTheSelectedRow() {
        var list = list()
        _ = list.handle(.down)
        guard case .choose(let row) = list.handle(.choose) else {
            Issue.record("expected choose")
            return
        }
        #expect(row == "b")
    }

    @Test func chooseWithNoRowsStays() {
        var empty = list([])
        guard case .stay = empty.handle(.choose) else {
            Issue.record("expected stay")
            return
        }
    }

    @Test func closeAndSwitchArePassedOn() {
        var list = list()
        guard case .close = list.handle(.close), case .switchList = list.handle(.switchList) else {
            Issue.record("expected close and switchList")
            return
        }
    }

    @Test func deleteTakesTheRowOutAndSelectsTheNext() {
        var list = list()
        _ = list.handle(.down)
        guard case .delete(let row) = list.handle(.delete) else {
            Issue.record("expected delete")
            return
        }
        #expect(row == "b")
        #expect(list.rows == ["a", "c", "d"])
        #expect(list.selected == "c")
    }

    @Test func deletingTheLastRowSelectsTheNewLast() {
        var list = list(["a", "b"])
        _ = list.handle(.down)
        _ = list.handle(.delete)
        #expect(list.selected == "a")
        _ = list.handle(.delete)
        #expect(list.selection == nil)
    }

    @Test func deleteDoesNothingWhenRowsCantBeDeleted() {
        var list = list(canDelete: false)
        _ = list.handle(.delete)
        #expect(list.rows.count == 4)
    }

    @Test func selectIgnoresAPlaceOutsideTheRows() {
        var list = list()
        list.select(9)
        #expect(list.selected == "a")
        list.select(3)
        #expect(list.selected == "d")
    }
}
