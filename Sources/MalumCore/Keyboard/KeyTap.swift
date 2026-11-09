/// What the event tap does with each keyboard event: one event in, one decision out.
///
/// The hyper key arrives as `KeyMapping.hyperTarget`. It's swallowed, and while it's held every
/// other key gets all four modifiers, so other apps see a normal hyper combination. A shortcut a
/// module handles runs once, never on repeat, and its key-up is swallowed too. hyper+tab opens the
/// app switcher as cmd+tab does, and keeps it open until the hyper key is let go.
///
/// It does no I/O, so the tap callback stays within its budget.
struct KeyTap: Sendable {
    /// What the hyper key holds down.
    private static let hyper = Set(Modifier.allCases)
    /// What the app switcher is held open with.
    private static let switcher: Set<Modifier> = [.cmd]

    /// Where each shortcut goes.
    private let registry: HotkeyRegistry
    /// Whether a hyper key is set, so F18 is the hyper key and not a key of its own.
    private let hasHyperKey: Bool
    /// Whether the hyper key is held down.
    private var hyperHeld = false
    /// Whether the app switcher is open from hyper+tab.
    private var switching = false
    /// Keys whose key-down was swallowed, so their repeats and key-up are swallowed too.
    private var swallowed: Set<UInt16> = []

    /// Starts with nothing held, sending shortcuts to `registry`, with `hyperKey` from `keyboard.toml`.
    init(registry: HotkeyRegistry, hyperKey: Key?) {
        self.registry = registry
        hasHyperKey = hyperKey != nil
    }

    /// What to do with `event`.
    mutating func decide(_ event: TapEvent) -> TapDecision {
        switch event {
        case .key(let press):
            return decide(press)
        case .modifiersChanged(let held):
            // Shift, to go back through the apps, must not look like cmd let go.
            guard switching else { return .pass }
            return .passAs(held.union(Self.switcher))
        case .switchedOff:
            swallowed.removeAll()
            guard letGo() else { return .pass }
            return .closeSwitcher
        }
    }

    /// What to do with `press`.
    private mutating func decide(_ press: KeyPress) -> TapDecision {
        if hasHyperKey, press.keyCode == KeyMapping.hyperTarget.keyCode {
            return hyperKey(press)
        }
        guard press.isDown else { return release(press) }
        if press.isRepeat, swallowed.contains(press.keyCode) {
            return .swallow
        }
        if let target = target(of: press) {
            swallowed.insert(press.keyCode)
            guard press.isRepeat else { return .run(target) }
            return .swallow
        }
        guard hyperHeld else { return .pass }
        if !switching, press.keyCode == Key.tab.keyCode {
            return openSwitcher(press)
        }
        return passHeld(press)
    }

    /// Holds the hyper key down or lets it go, swallowing it either way.
    private mutating func hyperKey(_ press: KeyPress) -> TapDecision {
        guard !press.isDown else {
            hyperHeld = true
            return .swallow
        }
        guard letGo() else { return .swallow }
        return .closeSwitcher
    }

    /// Swallows the key-up of a swallowed key-down, and adds what the hyper key holds to the others.
    private mutating func release(_ press: KeyPress) -> TapDecision {
        guard swallowed.remove(press.keyCode) == nil else { return .swallow }
        guard hyperHeld else { return .pass }
        return passHeld(press)
    }

    /// Opens the app switcher with the tab in `press`.
    private mutating func openSwitcher(_ press: KeyPress) -> TapDecision {
        switching = true
        swallowed.insert(press.keyCode)
        return .openSwitcher(Self.switcherModifiers(press))
    }

    /// `press` with the hyper key held: as cmd while the app switcher is open, as hyper otherwise.
    private func passHeld(_ press: KeyPress) -> TapDecision {
        guard switching else { return .passAs(Self.hyper) }
        return .passAs(Self.switcherModifiers(press))
    }

    /// The shortcut `press` makes, or nil when no module has it. A key with no modifiers is never one.
    private func target(of press: KeyPress) -> HotkeyTarget? {
        let modifiers = hyperHeld ? Self.hyper : press.modifiers
        guard !modifiers.isEmpty, let key = Key.coded(press.keyCode) else { return nil }
        return registry.target(for: Hotkey(modifiers: modifiers, key: key))
    }

    /// Lets go of the hyper key and closes the app switcher. Says whether the switcher was open.
    private mutating func letGo() -> Bool {
        let wasSwitching = switching
        hyperHeld = false
        switching = false
        return wasSwitching
    }

    /// cmd for the app switcher, with shift when `press` holds it, which goes back through the apps.
    private static func switcherModifiers(_ press: KeyPress) -> Set<Modifier> {
        press.modifiers.contains(.shift) ? switcher.union([.shift]) : switcher
    }
}
