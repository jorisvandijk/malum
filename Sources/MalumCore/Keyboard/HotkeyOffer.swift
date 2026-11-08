/// What a module brings to the hotkey registry: the actions `keyboard.toml` can bind keys to, the
/// keys it claims for itself whatever `keyboard.toml` says, and whether it opens apps.
public struct HotkeyOffer: Sendable {
    /// The actions it offers by name, such as `launcher`.
    let actions: Set<String>
    /// The keys it claims, each with the action it runs, such as cmd+h for the window manager.
    let fixedKeys: [Hotkey: String]
    /// Whether it handles the shortcuts bound to an app's bundle ID.
    let opensApps: Bool

    /// Creates an offer, by default of nothing.
    init(actions: Set<String> = [], fixedKeys: [Hotkey: String] = [:], opensApps: Bool = false) {
        self.actions = actions
        self.fixedKeys = fixedKeys
        self.opensApps = opensApps
    }
}
