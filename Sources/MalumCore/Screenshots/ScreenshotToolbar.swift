/// What the screenshot toolbar has picked: the tool, the color, the size and where the bar sits.
/// It always starts at the top with the select tool, the first quick color and the medium size.
public struct ScreenshotToolbar: Equatable, Sendable {
    /// The quick colors, from the settings.
    public let quickColors: [ScreenshotColor]
    /// The tool a drag or click uses.
    public private(set) var tool = ScreenshotTool.select
    /// The color new annotations are drawn in.
    public var color: ScreenshotColor
    /// The line width and text size of new annotations.
    public private(set) var size = AnnotationSize.medium
    /// Whether the bar sits at the bottom of the screen, for this shot only.
    public private(set) var isAtBottom = false

    /// Creates the toolbar of a new shot with `quickColors`, the first being the color to start with.
    public init(quickColors: [ScreenshotColor]) {
        self.quickColors = quickColors
        color =
            quickColors.first ?? ScreenshotColor.quickDefaults.first ?? ScreenshotColor(red: .max, green: 0, blue: 0)
    }

    /// The quick color that's picked, or nil when the color came from the picker.
    public var quickColorIndex: Int? {
        quickColors.firstIndex(of: color)
    }

    /// Carries out `command` when it changes the toolbar, and says whether it did. Commands about the
    /// shot or the view (undo, zoom, save…) are left to the overlay.
    public mutating func perform(_ command: ScreenshotCommand) -> Bool {
        switch command {
        case .tool(let picked):
            tool = picked
        case .quickColor(let index):
            guard quickColors.indices.contains(index) else { return false }
            color = quickColors[index]
        case .smaller:
            size = size.smaller
        case .larger:
            size = size.larger
        case .moveToolbar:
            isAtBottom.toggle()
        case .colorPicker, .zoomIn, .zoomOut, .resetZoom, .undo, .redo, .save, .cancel:
            return false
        }
        return true
    }
}
