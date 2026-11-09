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
    /// How often the pointer is looked at while a window is dragged.
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
    /// The windows it knows, oldest first, since the order decides which one gets the left half.
    private var windows: [TrackedWindow] = []
    /// How many looks again were taken for windows that weren't ready.
    private var readyTriesTaken = 0
    /// Whether a look again is waiting.
    private var isRetryPending = false
    /// Whether a drag is being followed.
    private var isFollowingDrag = false

    /// Starts tracking `app`, whose windows `watched` reaches.
    init(app: RunningApp, watched: any WatchedApp, access: any WindowAccess, scheduler: any WindowScheduler, log: Log) {
        self.app = app
        self.watched = watched
        self.access = access
        self.scheduler = scheduler
        self.log = log
    }

    /// Reacts to what happened to the app's windows. A window being dragged is left to follow the
    /// pointer, and drops into place once the button is let go.
    func handle(_ event: WindowEvent) {
        guard event == .moved, access.isPointerDown else {
            reconcile()
            return
        }
        followDrag()
    }

    /// Reads the app's windows again: forgets closed ones, sorts out new ones and puts the managed
    /// ones in place. A hidden app is left until it comes back, since its windows can say the wrong
    /// kind while hidden, and nobody sees them anyway.
    func reconcile() {
        guard !watched.isHidden, let current = watched.windows() else { return }
        windows.removeAll { known in !current.contains { $0.isSame(as: known.window) } }
        for window in current where !windows.contains(where: { $0.window.isSame(as: window) }) {
            windows.append(TrackedWindow(window))
        }
        for tracked in windows {
            classify(tracked)
        }
        layout()
        guard windows.contains(where: { $0.kind == .notReady }) else {
            readyTriesTaken = 0
            return
        }
        retryLater()
    }

    /// Stops tracking the app.
    func stop() {
        watched.stop()
    }

    /// Puts every managed window that's in view in its slot, unless it's already there.
    func layout() {
        guard let area else { return }
        let managed = windows.filter { $0.kind == .managed && !$0.window.isMinimized }
        for (tracked, slot) in zip(managed, WindowLayout.slots(count: managed.count, in: area)) {
            guard tracked.slot == slot, let settled = tracked.settled else {
                tracked.snaps = []
                place(tracked, in: slot)
                continue
            }
            guard let current = tracked.window.frame, !WindowLayout.isSame(current, settled) else { continue }
            snapBack(tracked, from: current, to: slot)
        }
    }

    /// Sorts out what to do with `tracked`. A window that briefly stops answering keeps what it was.
    private func classify(_ tracked: TrackedWindow) {
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

    /// Waits until the pointer's button is let go, then puts the windows back in place.
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
        reconcile()
    }
}
