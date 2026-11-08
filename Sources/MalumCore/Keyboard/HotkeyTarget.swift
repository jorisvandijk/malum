/// Where a registered shortcut goes: the module that handles it, and what it's asked to do.
struct HotkeyTarget: Equatable, Sendable {
    /// The id of the module that handles it.
    let module: String
    /// One of the module's actions, or the app it opens.
    let action: KeyAction
}
