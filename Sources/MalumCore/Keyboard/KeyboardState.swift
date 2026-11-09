/// What macOS says about the keyboard that the keyboard module isn't told about when it changes, so
/// it looks again every few seconds. `SystemKeyboardState` in MalumPlatform is the real one.
@MainActor
public protocol KeyboardState: AnyObject {
    /// Whether secure input is on now, and in which app.
    var secureInput: SecureInput { get }
    /// The key swaps set per keyboard in System Settings under Modifier Keys, each as macOS keeps it:
    /// the pressed and typed HID usages under `HIDKeyboardModifierMappingSrc` and `Dst`.
    var modifierSwaps: [[String: UInt64]] { get }
}
