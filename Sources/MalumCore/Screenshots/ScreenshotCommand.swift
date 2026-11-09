/// What a key or toolbar button asks of the screenshot overlay.
public enum ScreenshotCommand: Equatable, Hashable, Sendable {
    /// Picks a tool.
    case tool(ScreenshotTool)
    /// Picks the quick color at this place in the toolbar, counting from 0.
    case quickColor(Int)
    /// Opens macOS's color picker.
    case colorPicker
    /// Picks the next thinner line or smaller text.
    case smaller
    /// Picks the next thicker line or bigger text.
    case larger
    /// Moves the toolbar between the top and the bottom of the screen.
    case moveToolbar
    /// Zooms the view in.
    case zoomIn
    /// Zooms the view out.
    case zoomOut
    /// Shows the shot at its real size again.
    case resetZoom
    /// Takes back the latest step.
    case undo
    /// Puts back the latest undone step.
    case redo
    /// Saves the shot and closes the overlay.
    case save
    /// Closes the overlay without saving.
    case cancel
}
