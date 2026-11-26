import Foundation
import Testing

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AppTrackerSplitTests {
    private let area = CGRect(x: 0, y: 25, width: 1512, height: 957)
    private let watched = FakeWatchedApp()
    private let access = FakeWindowAccess()
    private let scheduler = FakeScheduler()
    private let writer = RecordingLogWriter()

    /// A tracker for kitty, filling `area`.
    private func tracker() -> AppTracker {
        let app = RunningApp(
            pid: 1, bundleID: "net.kovidgoyal.kitty", name: "kitty", isActive: true, isHidden: false, isRegular: true)
        let tracker = AppTracker(
            app: app, watched: watched, access: access, scheduler: scheduler, log: Log(writer: writer))
        tracker.area = area
        return tracker
    }

    @Test func splitLeftAndRightMoveTheBorderBetweenTheColumns() {
        let first = FakeAppWindow()
        let second = FakeAppWindow()
        watched.current = [first, second]
        let tracker = tracker()
        tracker.reconcile()
        tracker.resize(.right, by: 0.05)
        #expect(first.frame?.width == (area.width * 0.55).rounded(.down))
        #expect(second.frame?.minX == first.frame?.maxX)
        tracker.resize(.left, by: 0.05)
        #expect(first.frame == WindowLayout.slots(count: 2, in: area).first)
    }

    @Test func splitTallerResizesTheFocusedWindowInTheRightColumn() {
        let windows = [FakeAppWindow(), FakeAppWindow(), FakeAppWindow()]
        watched.current = windows
        let tracker = tracker()
        tracker.reconcile()
        watched.focused = windows[1]
        tracker.resize(.taller, by: 0.1)
        var split = Split()
        split.resizeRow(0, of: 2, by: 0.1)
        #expect(windows[1].frame == WindowLayout.slots(count: 3, in: area, split: split)[1])
        #expect(tracker.split == split)
    }

    @Test func splitShorterGivesTheFocusedWindowsHeightAway() {
        let windows = [FakeAppWindow(), FakeAppWindow(), FakeAppWindow()]
        watched.current = windows
        let tracker = tracker()
        tracker.reconcile()
        watched.focused = windows[2]
        tracker.resize(.shorter, by: 0.1)
        #expect(tracker.split.rowShares(count: 2) == [0.6, 0.4])
        #expect(windows[1].frame == WindowLayout.slots(count: 3, in: area, split: tracker.split)[1])
    }

    @Test func splitTallerLeavesTheLeftWindowAndASingleWindowAlone() {
        let first = FakeAppWindow()
        let second = FakeAppWindow()
        watched.current = [first, second]
        let tracker = tracker()
        tracker.reconcile()
        watched.focused = first
        tracker.resize(.taller, by: 0.1)
        #expect(tracker.split == Split())
        watched.current = [first]
        tracker.reconcile()
        tracker.resize(.right, by: 0.1)
        #expect(tracker.split == Split())
        #expect(first.frame == area)
    }
}

// MARK: - Hyper drags

extension AppTrackerSplitTests {
    /// Two windows of a tracked kitty, put in their slots.
    private func twoWindows() -> (AppTracker, [FakeAppWindow]) {
        let windows = [FakeAppWindow(), FakeAppWindow()]
        watched.current = windows
        let tracker = tracker()
        tracker.reconcile()
        return (tracker, windows)
    }

    /// The left window's width with the divider moved by `step`.
    private func leftWidth(movedBy step: CGFloat) -> CGFloat? {
        var split = Split()
        split.moveDivider(by: step)
        return WindowLayout.slots(count: 2, in: area, split: split).first?.width
    }

    @Test func hyperDragMovesTheDividerLive() {
        let (tracker, windows) = twoWindows()
        tracker.beginSplitDrag(at: CGPoint(x: 700, y: 400))
        tracker.moveSplitDrag(to: CGPoint(x: 700 + area.width * 0.1, y: 400))
        #expect(windows.first?.frame?.width == leftWidth(movedBy: 0.1))
        #expect(windows.last?.frame?.minX == windows.first?.frame?.maxX)
    }

    @Test func hyperDragLaysOutAtMostOncePerPoll() {
        let (tracker, windows) = twoWindows()
        tracker.beginSplitDrag(at: CGPoint(x: 700, y: 400))
        tracker.moveSplitDrag(to: CGPoint(x: 700 + area.width * 0.1, y: 400))
        tracker.moveSplitDrag(to: CGPoint(x: 700 + area.width * 0.15, y: 400))
        tracker.moveSplitDrag(to: CGPoint(x: 700 + area.width * 0.2, y: 400))
        #expect(windows.first?.frame?.width == leftWidth(movedBy: 0.1))
        scheduler.runPending()
        #expect(windows.first?.frame?.width == leftWidth(movedBy: 0.2))
        scheduler.runPending()
        #expect(scheduler.pending.isEmpty)
    }

    @Test func endingTheHyperDragKeepsTheSplit() {
        let (tracker, windows) = twoWindows()
        tracker.beginSplitDrag(at: CGPoint(x: 700, y: 400))
        tracker.endSplitDrag(at: CGPoint(x: 700 - area.width * 0.1, y: 400))
        var expected = Split()
        expected.moveDivider(by: -0.1)
        #expect(tracker.split == expected)
        #expect(windows.first?.frame?.width == leftWidth(movedBy: -0.1))
        tracker.moveSplitDrag(to: CGPoint(x: 1000, y: 400))
        #expect(tracker.split == expected)
    }

    @Test func nothingSnapsBackDuringTheHyperDrag() {
        let (tracker, windows) = twoWindows()
        tracker.beginSplitDrag(at: CGPoint(x: 700, y: 400))
        let pushed = CGRect(x: 0, y: 25, width: 400, height: 957)
        windows.first?.frame = pushed
        tracker.handle(.moved)
        #expect(windows.first?.frame == pushed)
        tracker.endSplitDrag(at: CGPoint(x: 700, y: 400))
        #expect(windows.first?.frame == WindowLayout.slots(count: 2, in: area).first)
    }

    @Test func hyperDragOnASingleWindowMovesNothing() {
        let window = FakeAppWindow()
        watched.current = [window]
        let tracker = tracker()
        tracker.reconcile()
        tracker.beginSplitDrag(at: CGPoint(x: 700, y: 400))
        tracker.moveSplitDrag(to: CGPoint(x: 900, y: 400))
        tracker.endSplitDrag(at: CGPoint(x: 900, y: 400))
        #expect(tracker.split == Split())
        #expect(window.frame == area)
    }
}
