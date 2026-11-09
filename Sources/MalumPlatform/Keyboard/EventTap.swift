import MalumCore

/// The keyboard event tap: catches every key press before any app sees it, lets a `TapSession`
/// decide what to do with it, and does that.
///
/// The tap runs on its own thread, and shortcuts go out on the session's `actions` for the main
/// actor to run. macOS switches a tap off when it's too slow; it's switched straight back on, and
/// the session starts over with nothing held.
///
/// Creating the tap needs Accessibility, and Accessibility alone: a tap that changes events doesn't
/// need Input Monitoring, which only a tap that listens asks for.
@MainActor
public final class EventTap {
    /// The tap that runs now, if any.
    private var thread: TapThread?

    /// A tap that isn't running yet.
    public init() {}

    /// Whether the tap is catching keys. macOS switches it off for good when Accessibility is taken away.
    public var isRunning: Bool { thread?.isRunning ?? false }

    /// Starts catching keys for `session`, stopping the tap that ran before. False when macOS refuses
    /// the tap, which means Accessibility is missing.
    public func start(_ session: TapSession) -> Bool {
        stop()
        let thread = TapThread(session: session)
        guard thread.start() else { return false }
        self.thread = thread
        return true
    }

    /// Stops catching keys and lets go of whatever the tap held, such as the app switcher.
    public func stop() {
        thread?.stop()
        thread = nil
    }
}

// MARK: - KeyCatcher

extension EventTap: KeyCatcher {}
