/// The part of the screen windows fill.
public enum ScreenFrame: String, CaseIterable, Sendable {
    /// Below the menu bar and outside the Dock.
    case visible
    /// The whole screen, the menu bar's strip included.
    case full
}
