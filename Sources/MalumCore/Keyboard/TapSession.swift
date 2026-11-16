import Synchronization

/// One run of the event tap: the `KeyTap` its thread and the main actor share, and the shortcuts it
/// caught for the main actor to run.
///
/// The tap's callback decides each event here and only ever waits on the lock around `KeyTap`,
/// which nothing holds for longer than one decision. A shortcut to run goes out on `actions`
/// without waiting for anyone to read it.
public final class TapSession: Sendable {
    /// The shortcuts the tap caught, in the order they were pressed. Finishes when the session ends.
    public let actions: AsyncStream<HotkeyTarget>
    /// Hands shortcuts to `actions`.
    private let continuation: AsyncStream<HotkeyTarget>.Continuation
    /// What is held down, shared by the tap's thread and whoever ends the session. Nil once the
    /// session has ended.
    private let keyTap: Mutex<KeyTap?>
    /// How often macOS switched the tap off since `takeSwitchOffs` last asked.
    private let switchOffs = Atomic<Int>(0)

    /// Starts with nothing held, sending shortcuts to `registry`, with `hyperKey` from `keyboard.toml`.
    init(registry: HotkeyRegistry, hyperKey: Key?) {
        keyTap = Mutex(KeyTap(registry: registry, hyperKey: hyperKey))
        (actions, continuation) = AsyncStream.makeStream()
    }

    /// What to do with `event`. A shortcut to run also goes out on `actions`. Once the session has
    /// ended, every event passes, so a callback that was already running holds nothing down that
    /// no one lets go of.
    public func decide(_ event: TapEvent) -> TapDecision {
        if event == .switchedOff {
            switchOffs.add(1, ordering: .relaxed)
        }
        let decision = keyTap.withLock { $0?.decide(event) ?? .pass }
        if case .run(let target) = decision {
            continuation.yield(target)
        }
        return decision
    }

    /// How often macOS switched the tap off since the last time this was asked.
    func takeSwitchOffs() -> Int {
        switchOffs.exchange(0, ordering: .relaxed)
    }

    /// Lets go of whatever the tap held and finishes `actions`. The decision says whether the app
    /// switcher still has to be closed.
    public func end() -> TapDecision {
        let decision = keyTap.withLock { keyTap in
            defer { keyTap = nil }
            return keyTap?.decide(.switchedOff) ?? .pass
        }
        continuation.finish()
        return decision
    }
}
