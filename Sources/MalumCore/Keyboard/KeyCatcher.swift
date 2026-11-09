/// Catches every key press before any app sees it, for the keyboard module. `EventTap` in
/// MalumPlatform is the real one.
@MainActor
public protocol KeyCatcher: AnyObject {
    /// Starts catching keys for `session`, stopping whatever ran before. False when macOS refuses.
    func start(_ session: TapSession) -> Bool
    /// Stops catching keys and lets go of whatever was held.
    func stop()
    /// Whether keys are being caught. macOS switches a tap off for good when Accessibility is taken away.
    var isRunning: Bool { get }
}
