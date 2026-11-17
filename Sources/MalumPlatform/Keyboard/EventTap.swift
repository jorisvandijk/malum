import Foundation
import MalumCore

/// The keyboard event tap: catches every key press before any app sees it, lets a `TapSession`
/// decide what to do with it, and does that.
///
/// The tap runs on its own thread, and shortcuts go out on the session's `actions` for the main
/// actor to run. macOS switches a tap off when it's too slow; it's switched straight back on, and
/// the session starts over with nothing held.
///
/// While it runs, macOS is asked not to nap Malum. A napped app runs at background priority, so
/// its tap answers too late: keys wait, then macOS switches the tap off and the hyper key types F18.
///
/// Creating the tap needs Accessibility, and Accessibility alone: a tap that changes events doesn't
/// need Input Monitoring, which only a tap that listens asks for.
@MainActor
public final class EventTap {
    /// How Malum stays awake while the tap runs: never napped and answering at once, while the Mac
    /// may still sleep when idle.
    private static let awake: ProcessInfo.ActivityOptions = [.userInitiatedAllowingIdleSystemSleep, .latencyCritical]

    /// The tap that runs now, if any.
    private var thread: TapThread?
    /// Keeps macOS from napping Malum while the tap runs.
    private var activity: (any NSObjectProtocol)?

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
        activity = ProcessInfo.processInfo.beginActivity(
            options: Self.awake, reason: MessageText.catchingKeys.description)
        return true
    }

    /// Stops catching keys and lets go of whatever the tap held, such as the app switcher.
    public func stop() {
        thread?.stop()
        thread = nil
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        activity = nil
    }
}

// MARK: - KeyCatcher

extension EventTap: KeyCatcher {}
