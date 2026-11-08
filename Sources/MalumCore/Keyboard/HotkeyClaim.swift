/// Something only one module can have in the hotkey registry.
enum HotkeyClaim: Hashable {
    /// An action by name, such as `launcher`.
    case action(String)
    /// Opening the apps that shortcuts name by bundle ID.
    case apps
    /// A key it claims for itself.
    case key(Hotkey)
}
