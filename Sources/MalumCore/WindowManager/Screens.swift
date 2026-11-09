/// Tells the window manager about the screen windows fill. Malum fills one screen, the one with the
/// menu bar, as silo does. `MainScreen` in MalumPlatform is the real one.
@MainActor
public protocol Screens: AnyObject {
    /// The screen with the menu bar, or nil when there's no screen, such as with the lid shut.
    func main() -> ScreenRects?
}
