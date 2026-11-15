/// Lets the user click one window, for the window inspector. `ClickPicker` in MalumPlatform is the
/// real one.
@MainActor
public protocol WindowPicker: AnyObject {
    /// Waits for a click, and says whether there was one or the user cancelled. The click itself
    /// never reaches the window, and the pointer is still where it was clicked once this returns.
    func pick() async -> Bool
}
