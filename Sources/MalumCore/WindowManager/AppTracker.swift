import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// Keeps one app's managed windows in their slots: reads its windows when they change, sorts out
/// which to manage, puts them in place and snaps them back when they're moved or resized.
@MainActor
final class AppTracker {
    /// How many times a window that doesn't say what it is yet is looked at again.
    private static let readyTries = 8
    /// How long to wait before looking again, so all tries take about 400 ms.
    private static let readyDelayMilliseconds = 50
    /// How many times a window that didn't take its slot is put there again.
    private static let placeTries = 3
    /// How long to wait before putting it there again, so a window that wasn't ready gets about 200 ms.
    private static let placeDelayMilliseconds = 70
    /// How often the pointer is looked at while a window is dragged, and how often at most the
    /// windows are laid out again while a hyper drag moves the borders.
    private static let dragPollMilliseconds = 50
    /// How many snaps back within `fightSpan` mean the app keeps changing its window's frame itself.
    private static let fightLimit = 5
    /// The span `fightLimit` counts snaps back in.
    private static let fightSpan = Duration.seconds(1)

    /// The app.
    let app: RunningApp
    /// Its windows, through Accessibility.
    private let watched: any WatchedApp
    /// Tells whether the pointer's button is held.
    private let access: any WindowAccess
    /// Runs the later looks.
    private let scheduler: any WindowScheduler
    /// The window manager's log.
    private let log: Log
    /// The settings, for the float rules.
    var config = WindowManagerConfig()
    /// The area windows fill, in Accessibility's coordinates, or nil when there's no screen.
    var area: CGRect?
    /// How the area is shared out between the managed windows. The module keeps it per app while
    /// the app isn't running.
    var split = Split()
    /// The windows it knows, oldest first, since the order decides which one gets the left half.
    private var windows: [TrackedWindow] = []
    /// How many looks again were taken for windows that weren't ready.
    private var readyTriesTaken = 0
    /// Whether a look again is waiting.
    private var isRetryPending = false
    /// Whether a drag is being followed.
    private var isFollowingDrag = false
    /// The hyper drag moving the borders, while one runs.
    private var splitDrag: SplitDrag?
    /// Where the pointer went in the hyper drag since the windows were last laid out, if it moved.
    private var splitDragPoint: CGPoint?
    /// Whether the windows were laid out for the hyper drag too recently to do it again yet.
    private var isSplitDragPaused = false
    /// Whether the managed windows are stacked, each filling the area with one in front, rather
    /// than split. Kept only while the app runs.
    private(set) var isStacked = false
    /// Which stacked window is shown.
    private var stack = WindowStack<ObjectIdentifier>()
    /// The stacked window last known to be in front, to raise the shown one only when it changes.
    private var inFront: ObjectIdentifier?

    /// Starts tracking `app`, whose windows `watched` reaches.
    init(app: RunningApp, watched: any WatchedApp, access: any WindowAccess, scheduler: any WindowScheduler, log: Log) {
        self.app = app
        self.watched = watched
        self.access = access
        self.scheduler = scheduler
        self.log = log
    }

    /// Reacts to what happened to the app's windows. A window being dragged is left to follow the
    /// pointer, and drops into place once the button is let go. Nothing snaps back during a hyper
    /// drag, which moves the windows itself; they're read again when it ends.
    func handle(_ event: WindowEvent) {
        guard splitDrag == nil else { return }
        guard event == .moved, access.isPointerDown else {
            reconcile()
            return
        }
        followDrag()
    }

    /// What it decided about `window`, or nil when it doesn't know the window yet.
    func kind(of window: any AppWindow) -> WindowKind? {
        windows.first { $0.window.isSame(as: window) }?.kind
    }

    /// Reads the app's windows again: forgets closed ones, sorts out new ones and puts the managed
    /// ones in place. A hidden app is left until it comes back, since its windows can say the wrong
    /// kind while hidden, and nobody sees them anyway.
    func reconcile() {
        guard !watched.isHidden, let current = watched.windows() else { return }
        let before = managedInView
        windows.removeAll { known in !current.contains { $0.isSame(as: known.window) } }
        stack.keep(windows.map(ObjectIdentifier.init))
        for window in current where !windows.contains(where: { $0.window.isSame(as: window) }) {
            windows.append(TrackedWindow(window))
        }
        for tracked in windows {
            classify(tracked)
        }
        // One window left ends the stack, so the next new one is split with it again.
        isStacked = isStacked && managedInView.count > 1
        followFocus()
        showJoined(since: before)
        layout()
        bringShownToFront()
        guard windows.contains(where: { $0.kind == .notReady }) else {
            readyTriesTaken = 0
            return
        }
        retryLater()
    }

    /// Floats the app's focused window, centred and smaller, or puts one floated this way back in
    /// its place. Its place is kept meanwhile, so it goes back where it came from. A window that
    /// floats for another reason is left as it is.
    func toggleFloat() {
        guard let focused = watched.focusedWindow(),
            let tracked = windows.first(where: { $0.window.isSame(as: focused) })
        else { return }
        switch tracked.kind {
        case .managed:
            tracked.kind = .float(.toggled)
            tracked.forgetPlace()
            log.report(.window(tracked.window.facts.title, of: app.name, is: tracked.kind))
            if let area {
                tracked.window.setFrame(WindowLayout.floated(in: area))
            }
        case .float(.toggled):
            tracked.kind = .notReady
            classify(tracked)
        case .float, .notReady:
            return
        }
        layout()
    }

    /// Moves a border between the managed windows by `step` of the area: sideways the one between
    /// the left window and the rest, up or down the focused window's in the right column. Nothing
    /// moves with one window, or up or down for the left window, which fills the height.
    func resize(_ move: SplitMove, by step: CGFloat) {
        let managed = managedInView
        guard !isStacked, managed.count > 1 else { return }
        switch move {
        case .left, .right:
            split.moveDivider(by: move == .left ? -step : step)
        case .taller, .shorter:
            guard let focused = watched.focusedWindow(),
                let index = managed.firstIndex(where: { $0.window.isSame(as: focused) }), index > 0
            else { return }
            split.resizeRow(index - 1, of: managed.count - 1, by: move == .taller ? step : -step)
        }
        layout()
    }

    /// Starts a hyper drag at `point` that moves the borders between the managed windows. Nothing
    /// moves with one window.
    func beginSplitDrag(at point: CGPoint) {
        guard !isStacked, let area else { return }
        splitDrag = SplitDrag(at: point, in: area, split: split, count: managedInView.count)
        splitDragPoint = nil
    }

    /// Moves the borders to follow the hyper drag to `point`, laying the windows out at most every
    /// `dragPollMilliseconds`, so a fast drag doesn't flood the app with resizes.
    func moveSplitDrag(to point: CGPoint) {
        guard splitDrag != nil else { return }
        splitDragPoint = point
        guard !isSplitDragPaused else { return }
        followSplitDrag()
    }

    /// Ends the hyper drag with the pointer at `point`, keeping the split it made.
    func endSplitDrag(at point: CGPoint) {
        guard let splitDrag else { return }
        split = splitDrag.split(at: point)
        self.splitDrag = nil
        splitDragPoint = nil
        reconcile()
    }

    /// Stops tracking the app.
    func stop() {
        watched.stop()
    }

    /// Puts every managed window that's in view in its slot, unless it's already there.
    func layout() {
        guard let area else { return }
        let managed = managedInView
        for (tracked, slot) in zip(managed, slots(count: managed.count, in: area)) {
            guard tracked.slot == slot, let settled = tracked.settled else {
                tracked.snaps = []
                place(tracked, in: slot)
                continue
            }
            guard let current = tracked.window.frame, !WindowLayout.isSame(current, settled) else { continue }
            snapBack(tracked, from: current, to: slot)
        }
    }

    /// The managed windows that aren't minimised, oldest first: the ones that get a slot.
    private var managedInView: [TrackedWindow] {
        windows.filter { $0.kind == .managed && !$0.window.isMinimized }
    }

    /// Where each of `count` managed windows goes in `area`: all of it each while stacked, or
    /// shared out by the split.
    private func slots(count: Int, in area: CGRect) -> [CGRect] {
        isStacked
            ? WindowLayout.stacked(count: count, in: area)
            : WindowLayout.slots(count: count, in: area, split: split)
    }

    /// Sorts out what to do with `tracked`. A window that briefly stops answering keeps what it was,
    /// and one the user floated stays floating.
    private func classify(_ tracked: TrackedWindow) {
        guard tracked.kind != .float(.toggled) else { return }
        let facts = tracked.window.facts
        let kind = WindowLayout.classify(facts, app: app.bundleID, floats: config.floats)
        guard kind != tracked.kind, kind != .notReady || tracked.kind == .notReady else { return }
        tracked.kind = kind
        tracked.forgetPlace()
        log.report(.window(facts.title, of: app.name, is: kind))
    }

    /// Puts `tracked`, which was moved or resized to `current`, back in `slot`, unless the app keeps
    /// changing it itself, which is then settled for rather than fought forever.
    private func snapBack(_ tracked: TrackedWindow, from current: CGRect, to slot: CGRect) {
        let now = scheduler.now
        tracked.snaps = tracked.snaps.filter { $0.duration(to: now) < Self.fightSpan } + [now]
        guard tracked.snaps.count <= Self.fightLimit else {
            log.report(.keepsResizing(app.name, current.size))
            tracked.settled = current
            return
        }
        place(tracked, in: slot)
    }

    /// Puts `tracked` in `slot`. A window that won't take the slot's size is centred in it, or pinned
    /// to its top left. One that ends up elsewhere is put there again a few times, since a window
    /// reported before it's ready ignores the first tries.
    private func place(_ tracked: TrackedWindow, in slot: CGRect, try number: Int = 1) {
        tracked.slot = slot
        tracked.window.setFrame(slot)
        guard let actual = tracked.window.frame else { return }
        let origin = WindowLayout.place(actual.size, in: slot)
        if !WindowLayout.isSame(CGRect(origin: origin, size: actual.size), actual) {
            tracked.window.setOrigin(origin)
        }
        let settled = tracked.window.frame ?? actual
        tracked.settled = settled
        guard !WindowLayout.isSame(settled, slot), number < Self.placeTries else { return }
        scheduler.after(.milliseconds(Self.placeDelayMilliseconds)) { [weak self, weak tracked] in
            guard let self, let tracked, tracked.slot == slot, tracked.kind == .managed else { return }
            self.place(tracked, in: slot, try: number + 1)
        }
    }

    /// Looks again shortly at windows that didn't say what they are, a few times at most. One that
    /// never says stays unmanaged.
    private func retryLater() {
        guard !isRetryPending, readyTriesTaken < Self.readyTries else { return }
        readyTriesTaken += 1
        isRetryPending = true
        scheduler.after(.milliseconds(Self.readyDelayMilliseconds)) { [weak self] in
            self?.isRetryPending = false
            self?.reconcile()
        }
    }

    /// Lays the windows out for where the hyper drag's pointer went, then waits `dragPollMilliseconds`
    /// before doing it again for wherever it goes meanwhile.
    private func followSplitDrag() {
        guard let splitDrag, let point = splitDragPoint else {
            isSplitDragPaused = false
            return
        }
        splitDragPoint = nil
        split = splitDrag.split(at: point)
        layout()
        isSplitDragPaused = true
        scheduler.after(.milliseconds(Self.dragPollMilliseconds)) { [weak self] in self?.followSplitDrag() }
    }

    /// Waits until the pointer's button is let go, then puts the windows back in place, swapping two
    /// when one was dropped on the other's slot.
    private func followDrag() {
        guard !isFollowingDrag else { return }
        isFollowingDrag = true
        checkDrag()
    }

    /// Puts the windows in place once the button is up, or looks again shortly.
    private func checkDrag() {
        guard !access.isPointerDown else {
            scheduler.after(.milliseconds(Self.dragPollMilliseconds)) { [weak self] in self?.checkDrag() }
            return
        }
        isFollowingDrag = false
        swapDropped()
        reconcile()
    }

    /// Swaps the window that was dragged with the one whose slot it was dropped on. The dragged one
    /// is the managed window that's no longer where it was put.
    private func swapDropped() {
        guard !isStacked, let area else { return }
        let managed = managedInView
        let slots = self.slots(count: managed.count, in: area)
        guard let from = managed.firstIndex(where: Self.wasMoved),
            let to = WindowLayout.dropTarget(at: access.pointerLocation, slots: slots, from: from),
            let first = windows.firstIndex(where: { $0 === managed[from] }),
            let second = windows.firstIndex(where: { $0 === managed[to] })
        else { return }
        windows.swapAt(first, second)
    }

    /// Whether `tracked` is no longer where it was put.
    private static func wasMoved(_ tracked: TrackedWindow) -> Bool {
        guard let settled = tracked.settled, let frame = tracked.window.frame else { return false }
        return !WindowLayout.isSame(frame, settled)
    }
}

// MARK: - Stack

extension AppTracker {
    /// Stacks the managed windows, each filling the area with the focused one in front, or splits
    /// them again, by the split they had. One window alone isn't stacked.
    func toggleStack() {
        guard isStacked || managedInView.count > 1 else { return }
        isStacked.toggle()
        inFront = nil
        followFocus()
        layout()
        bringShownToFront()
    }

    /// Brings the stacked window `offset` places after the shown one to the front, oldest first and
    /// wrapping around, and gives it the focus.
    func showStacked(_ offset: Int) {
        guard isStacked, let next = stack.step(offset, among: stackedIDs) else { return }
        stack.show(next)
        bringShownToFront()
    }

    /// Raises the shown stacked window again, as when the app comes back to the front, in case
    /// macOS brought up another one. A managed window that has the focus is shown.
    func raiseShown() {
        followFocus()
        inFront = nil
        bringShownToFront()
    }

    /// The managed windows in view, by identity, which is how the stack names them.
    private var stackedIDs: [ObjectIdentifier] {
        managedInView.map(ObjectIdentifier.init)
    }

    /// Shows the focused window while stacked, when it's a managed one. It's in front already, since
    /// it has the focus, as after cmd+` or a click in the Window menu.
    private func followFocus() {
        guard isStacked, let focused = watched.focusedWindow(),
            let tracked = managedInView.first(where: { $0.window.isSame(as: focused) })
        else { return }
        stack.show(ObjectIdentifier(tracked))
        inFront = ObjectIdentifier(tracked)
    }

    /// Shows the newest managed window that joined the stack since `before`, such as a new or
    /// restored one, even when macOS hasn't said it has the focus yet. `before` also keeps the
    /// windows that closed meanwhile alive, so a new one never takes over a closed one's identity.
    private func showJoined(since before: [TrackedWindow]) {
        guard isStacked, let joined = managedInView.last(where: { tracked in !before.contains { $0 === tracked } })
        else { return }
        stack.show(ObjectIdentifier(joined))
    }

    /// Raises the shown stacked window when another one is in front, as after the shown one closed,
    /// so the one shown before it comes up.
    private func bringShownToFront() {
        guard isStacked else { return }
        let ids = stackedIDs
        stack.keep(ids)
        guard let shown = stack.shown(among: ids), shown != inFront,
            let tracked = windows.first(where: { ObjectIdentifier($0) == shown })
        else { return }
        inFront = shown
        tracked.window.raise()
    }
}
