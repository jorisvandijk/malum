import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct WindowStackTests {
    @Test func firstWindowIsShownWhenNoneWasShownYet() {
        #expect(WindowStack<Int>().shown(among: [1, 2]) == 1)
        #expect(WindowStack<Int>().shown(among: []) == nil)
    }

    @Test func shownWindowIsTheLastOneShown() {
        var stack = WindowStack<Int>()
        stack.show(2)
        stack.show(1)
        #expect(stack.shown(among: [1, 2]) == 1)
    }

    @Test func closedShownWindowGivesWayToTheOneShownBeforeIt() {
        var stack = WindowStack<Int>()
        stack.show(3)
        stack.show(1)
        stack.show(2)
        stack.keep([1, 3])
        #expect(stack.shown(among: [1, 3]) == 1)
    }

    @Test func stepWrapsAroundBothEnds() {
        var stack = WindowStack<Int>()
        stack.show(3)
        #expect(stack.step(1, among: [1, 2, 3]) == 1)
        stack.show(1)
        #expect(stack.step(-1, among: [1, 2, 3]) == 3)
        #expect(stack.step(1, among: [1, 2, 3]) == 2)
    }

    @Test func stepWithTwoWindowsTogglesBetweenThem() {
        var stack = WindowStack<Int>()
        stack.show(1)
        #expect(stack.step(1, among: [1, 2]) == 2)
        #expect(stack.step(-1, among: [1, 2]) == 2)
    }

    @Test func stepWithNoWindowsGivesNothing() {
        #expect(WindowStack<Int>().step(1, among: []) == nil)
    }
}
