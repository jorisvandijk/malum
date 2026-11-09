import Foundation
import Testing

@testable import MalumCore

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AppTrackerTests {
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

    @Test func oneWindowFillsTheArea() {
        let window = FakeAppWindow()
        watched.current = [window]
        tracker().reconcile()
        #expect(window.frame == area)
    }

    @Test func secondWindowTakesTheRightHalf() {
        let first = FakeAppWindow()
        let second = FakeAppWindow()
        watched.current = [first]
        let tracker = tracker()
        tracker.reconcile()
        watched.current = [second, first]
        tracker.reconcile()
        let slots = WindowLayout.slots(count: 2, in: area)
        #expect(first.frame == slots.first)
        #expect(second.frame == slots.last)
    }

    @Test func closedWindowLeavesTheAreaToTheOther() {
        let first = FakeAppWindow()
        let second = FakeAppWindow()
        watched.current = [first, second]
        let tracker = tracker()
        tracker.reconcile()
        watched.current = [second]
        tracker.reconcile()
        #expect(second.frame == area)
    }

    @Test func dialogFloatsWhereItIs() {
        let dialog = FakeAppWindow()
        dialog.facts.subrole = "AXDialog"
        watched.current = [dialog]
        tracker().reconcile()
        #expect(dialog.moves == 0)
        #expect(
            writer.entries.map(\.text) == [Message.window("Main", of: "kitty", is: .float(.subrole("AXDialog"))).text])
    }

    @Test func minimisedWindowIsLeftOut() {
        let window = FakeAppWindow()
        let minimized = FakeAppWindow()
        minimized.isMinimized = true
        watched.current = [window, minimized]
        tracker().reconcile()
        #expect(window.frame == area)
        #expect(minimized.moves == 0)
    }

    @Test func movedWindowSnapsBack() {
        let window = FakeAppWindow()
        watched.current = [window]
        let tracker = tracker()
        tracker.reconcile()
        window.frame = CGRect(x: 100, y: 100, width: 400, height: 300)
        tracker.handle(.moved)
        #expect(window.frame == area)
    }

    @Test func draggedWindowDropsIntoPlaceOnceLetGo() {
        let window = FakeAppWindow()
        watched.current = [window]
        let tracker = tracker()
        tracker.reconcile()
        let dragged = CGRect(x: 100, y: 100, width: 1512, height: 957)
        window.frame = dragged
        access.isPointerDown = true
        tracker.handle(.moved)
        scheduler.runPending()
        #expect(window.frame == dragged)
        access.isPointerDown = false
        scheduler.runPending()
        #expect(window.frame == area)
    }

    /// Two windows side by side, with the left one dragged and let go at `point`.
    private func dropLeftWindow(at point: CGPoint) -> (left: FakeAppWindow, right: FakeAppWindow) {
        let left = FakeAppWindow()
        let right = FakeAppWindow()
        watched.current = [left, right]
        let tracker = tracker()
        tracker.reconcile()
        left.frame = CGRect(origin: point, size: CGSize(width: 300, height: 200))
        access.isPointerDown = true
        tracker.handle(.moved)
        access.isPointerDown = false
        access.pointerLocation = point
        scheduler.runPending()
        return (left, right)
    }

    @Test func windowDroppedOnAnothersSlotSwapsWithIt() {
        let slots = WindowLayout.slots(count: 2, in: area)
        let (left, right) = dropLeftWindow(at: CGPoint(x: 1200, y: 500))
        #expect(left.frame == slots.last)
        #expect(right.frame == slots.first)
    }

    @Test func windowDroppedOnItsOwnSlotGoesBack() {
        let slots = WindowLayout.slots(count: 2, in: area)
        let (left, right) = dropLeftWindow(at: CGPoint(x: 200, y: 500))
        #expect(left.frame == slots.first)
        #expect(right.frame == slots.last)
    }

    @Test func appThatKeepsResizingIsLeftAlone() {
        let window = FakeAppWindow()
        watched.current = [window]
        let tracker = tracker()
        tracker.reconcile()
        let own = CGRect(x: 0, y: 25, width: 800, height: 600)
        for _ in 0...5 {
            window.frame = own
            tracker.handle(.moved)
        }
        #expect(window.frame == own)
        #expect(writer.entries.last?.text == Message.keepsResizing("kitty", own.size).text)
    }

    @Test func windowThatIsNotReadyIsLookedAtAgain() {
        let window = FakeAppWindow()
        window.facts = WindowFacts()
        watched.current = [window]
        let tracker = tracker()
        tracker.reconcile()
        #expect(window.moves == 0)
        window.facts = WindowFacts(role: "AXWindow", subrole: "AXStandardWindow")
        scheduler.runPending()
        #expect(window.frame == area)
    }

    @Test func windowThatNeverSaysWhatItIsIsLookedAtOnlyAFewTimes() {
        let window = FakeAppWindow()
        window.facts = WindowFacts()
        watched.current = [window]
        let tracker = tracker()
        tracker.reconcile()
        var looks = 0
        while !scheduler.pending.isEmpty {
            scheduler.runPending()
            looks += 1
        }
        #expect(looks == 8)
        #expect(window.moves == 0)
    }

    @Test func windowThatWontGrowIsCentred() {
        let window = FakeAppWindow()
        window.maxSize = CGSize(width: 1000, height: 957)
        watched.current = [window]
        tracker().reconcile()
        #expect(window.frame == CGRect(x: 256, y: 25, width: 1000, height: 957))
    }

    @Test func hiddenAppIsLeftUntilItComesBack() {
        let window = FakeAppWindow()
        watched.current = [window]
        watched.isHidden = true
        tracker().reconcile()
        #expect(window.moves == 0)
    }

    @Test func stopStopsWatching() {
        tracker().stop()
        #expect(watched.isStopped)
    }
}
