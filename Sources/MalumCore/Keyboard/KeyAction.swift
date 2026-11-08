/// What a shortcut in `keyboard.toml` does: open an app through the module that handles apps, or
/// run an action a module offers.
enum KeyAction: Equatable, Sendable {
    /// The app with this bundle ID, such as `com.apple.finder`.
    case app(String)
    /// The action a module offers by this name, such as `launcher`.
    case module(String)

    /// What every bundle ID holds and no module's action does.
    private static let bundleIDMark: Character = "."

    /// The action written as `text`: a bundle ID when it holds a dot, a module's action when it
    /// doesn't, or nil when it's empty.
    init?(_ text: String) {
        guard !text.isEmpty else { return nil }
        self = text.contains(Self.bundleIDMark) ? .app(text) : .module(text)
    }
}
