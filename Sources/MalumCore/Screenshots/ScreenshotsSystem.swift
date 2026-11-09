/// What the screenshots module works through.
@MainActor
public struct ScreenshotsSystem {
    /// Writes the shots.
    let files: any FileSystem
    /// Where home is, for the folder setting.
    let paths: Paths
    /// Freezes the screen.
    let capture: any ScreenCapture
    /// Shows the frozen screen to crop and draw on.
    let overlay: any ScreenshotOverlay
    /// The system clipboard, which gets every shot.
    let clipboard: any Clipboard

    /// Gathers the parts the screenshots module needs.
    public init(
        files: any FileSystem, paths: Paths, capture: any ScreenCapture, overlay: any ScreenshotOverlay,
        clipboard: any Clipboard
    ) {
        self.files = files
        self.paths = paths
        self.capture = capture
        self.overlay = overlay
        self.clipboard = clipboard
    }
}
