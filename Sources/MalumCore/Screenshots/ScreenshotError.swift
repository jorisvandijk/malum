/// Why taking or saving a screenshot failed.
public enum ScreenshotError: Error, Equatable, Sendable {
    /// No screen could be found under the mouse.
    case noScreen
    /// macOS didn't hand over the screen's pixels, with its reason.
    case captureFailed(String)
    /// The shot couldn't be turned into a PNG.
    case unencodable
}
