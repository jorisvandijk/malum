import Foundation
import Testing

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AppTrackerStackTests {
    private let area = CGRect(x: 0, y: 25, width: 1512, height: 957)
    private let watched = FakeWatchedApp()
    private let access = FakeWindowAccess()
    private let scheduler = FakeScheduler()

    /// A tracker for kitty filling `area`, with `count` windows put in place and the first focused.
    private func tracker(windows count: Int = 2) -> (AppTracker, [FakeAppWindow]) {
        let app = RunningApp(
            pid: 1, bundleID: "net.kovidgoyal.kitty", name: "kitty", isActive: true, isHidden: false, isRegular: true)
        let tracker = AppTracker(
            app: app, watched: watched, access: access, scheduler: scheduler, log: Log(writer: RecordingLogWriter()))
        tracker.area = area
        let windows = (0..<count).map { _ in FakeAppWindow() }
        watched.current = windows
        watched.focused = windows.first
        tracker.reconcile()
        return (tracker, windows)
    }

    /// Says `window` has the focus now, as macOS does after it's raised.
    private func focus(_ window: FakeAppWindow, in tracker: AppTracker) {
        watched.focused = window
        tracker.handle(.changed)
    }

    @Test func toggleStackFillsTheAreaWithEveryWindow() {
        let (tracker, windows) = tracker(windows: 3)
        tracker.toggleStack()
        #expect(windows.allSatisfy { $0.frame == area })
    }

    @Test func toggleStackLeavesTheFocusedWindowInFront() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        #expect(windows.map(\.raises) == [0, 0])
    }

    @Test func toggleStackAgainGoesBackToTheSplitItHad() {
        let (tracker, windows) = tracker()
        tracker.resize(.right, by: 0.1)
        let split = windows.map(\.frame)
        tracker.toggleStack()
        tracker.toggleStack()
        #expect(windows.map(\.frame) == split)
    }

    @Test func stackNextRaisesTheNextWindowAndWrapsAround() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        tracker.showStacked(1)
        #expect(windows.map(\.raises) == [0, 1])
        focus(windows[1], in: tracker)
        tracker.showStacked(1)
        #expect(windows.map(\.raises) == [1, 1])
    }

    @Test func stackPreviousGoesTheOtherWay() {
        let (tracker, windows) = tracker(windows: 3)
        tracker.toggleStack()
        tracker.showStacked(-1)
        #expect(windows.map(\.raises) == [0, 0, 1])
    }

    @Test func stackKeysDoNothingWhileSplit() {
        let (tracker, windows) = tracker()
        tracker.showStacked(1)
        #expect(windows.map(\.raises) == [0, 0])
    }

    @Test func focusedWindowBecomesTheShownOne() {
        let (tracker, windows) = tracker(windows: 3)
        tracker.toggleStack()
        focus(windows[2], in: tracker)
        tracker.showStacked(1)
        #expect(windows.map(\.raises) == [1, 0, 0])
    }

    @Test func closingTheShownWindowRaisesTheOneShownBeforeIt() {
        let (tracker, windows) = tracker(windows: 3)
        tracker.toggleStack()
        tracker.showStacked(-1)
        focus(windows[2], in: tracker)
        tracker.showStacked(-1)
        watched.current = windows.filter { $0 !== windows[1] }
        watched.focused = nil
        tracker.handle(.changed)
        #expect(windows[2].raises == 2)
    }

    @Test func comingBackToTheFrontRaisesTheShownWindowAgain() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        tracker.showStacked(1)
        watched.focused = nil
        tracker.raiseShown()
        #expect(windows.map(\.raises) == [0, 2])
    }

    @Test func comingBackToTheFrontWhileSplitRaisesNothing() {
        let (tracker, windows) = tracker()
        tracker.raiseShown()
        #expect(windows.map(\.raises) == [0, 0])
    }

    @Test func newWindowWhileStackedFillsTheAreaAndIsShown() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        let new = FakeAppWindow()
        watched.current = windows + [new]
        focus(new, in: tracker)
        #expect(new.frame == area)
        tracker.showStacked(1)
        #expect(windows.map(\.raises) == [1, 0])
    }

    @Test func splitKeysDoNothingWhileStacked() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        tracker.resize(.right, by: 0.1)
        #expect(windows.allSatisfy { $0.frame == area })
    }

    @Test func hyperDragDoesNothingWhileStacked() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        tracker.beginSplitDrag(at: CGPoint(x: 700, y: 400))
        tracker.endSplitDrag(at: CGPoint(x: 900, y: 400))
        #expect(windows.allSatisfy { $0.frame == area })
    }

    @Test func droppedWindowWhileStackedSwapsNothing() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        windows[1].setOrigin(CGPoint(x: 50, y: 80))
        access.isPointerDown = true
        tracker.handle(.moved)
        access.isPointerDown = false
        scheduler.runPending()
        tracker.showStacked(1)
        #expect(windows.map(\.raises) == [0, 1])
        #expect(windows.allSatisfy { $0.frame == area })
    }

    @Test func oneWindowStaysStackedUntilASecondComesBack() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        watched.current = Array(windows.prefix(1))
        watched.focused = windows.first
        tracker.handle(.changed)
        watched.current = windows
        tracker.reconcile()
        #expect(tracker.isStacked)
        #expect(windows.allSatisfy { $0.frame == area })
    }

    @Test func newWindowWithoutTheFocusIsShownToo() {
        let (tracker, windows) = tracker()
        tracker.toggleStack()
        let new = FakeAppWindow()
        watched.current = windows + [new]
        tracker.handle(.changed)
        #expect(new.raises == 1)
        tracker.showStacked(1)
        #expect(windows.map(\.raises) == [1, 0])
    }

    @Test func minimisingTheShownWindowRaisesTheOneShownBeforeIt() {
        let (tracker, windows) = tracker(windows: 3)
        tracker.toggleStack()
        tracker.showStacked(-1)
        windows[2].isMinimized = true
        watched.focused = nil
        tracker.handle(.changed)
        #expect(windows.map(\.raises) == [1, 0, 1])
    }

    @Test func floatingWindowIsLeftOutOfTheStack() {
        let (tracker, windows) = tracker(windows: 3)
        tracker.toggleStack()
        watched.focused = windows[1]
        tracker.toggleFloat()
        #expect(windows[1].frame == WindowLayout.floated(in: area))
        watched.focused = nil
        tracker.showStacked(1)
        tracker.showStacked(1)
        #expect(windows.map(\.raises) == [1, 0, 1])
    }

    @Test func newTrackerStartsSplit() {
        let (tracker, windows) = tracker()
        #expect(!tracker.isStacked)
        #expect(windows.map(\.frame) == WindowLayout.slots(count: 2, in: area))
    }
}
