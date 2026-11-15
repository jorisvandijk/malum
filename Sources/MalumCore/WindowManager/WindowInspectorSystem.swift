/// What the window inspector works through in macOS. The app builds the real ones; tests hand in
/// fakes.
@MainActor
public struct WindowInspectorSystem {
    /// Lets the user click a window.
    let picker: any WindowPicker
    /// Shows what was found.
    let panel: any InspectorPanel
    /// Takes the copied report.
    let clipboard: any Clipboard

    /// Gathers the parts the window inspector needs.
    public init(picker: any WindowPicker, panel: any InspectorPanel, clipboard: any Clipboard) {
        self.picker = picker
        self.panel = panel
        self.clipboard = clipboard
    }
}
