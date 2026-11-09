/// What the event tap does with an event, as `KeyTap` decides it.
enum TapDecision: Equatable, Sendable {
    /// Let the event through as it is.
    case pass
    /// Let the event through with exactly these modifiers held.
    case passAs(Set<Modifier>)
    /// Drop the event.
    case swallow
    /// Drop the event and hand this shortcut's action to its module.
    case run(HotkeyTarget)
    /// Drop the event, hold cmd down and press tab once with these modifiers, which opens the app
    /// switcher and keeps it open.
    case openSwitcher(Set<Modifier>)
    /// Drop the event and let go of the cmd `openSwitcher` held, which picks the app.
    case closeSwitcher
}
