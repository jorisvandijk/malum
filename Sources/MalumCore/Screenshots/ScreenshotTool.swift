/// What a drag or click on the frozen screen does.
public enum ScreenshotTool: CaseIterable, Equatable, Sendable {
    /// Picks the part of the screen to keep.
    case select
    /// Draws a straight line.
    case line
    /// Draws a line with an arrowhead at its end.
    case arrow
    /// Draws the outline of a rectangle.
    case rectangle
    /// Places text.
    case text
}
