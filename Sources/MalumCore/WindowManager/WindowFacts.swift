/// What Accessibility says about a window, everything `WindowLayout.classify` looks at.
struct WindowFacts: Equatable, Sendable {
    /// Its role, such as `AXWindow`, or nil when it doesn't say yet.
    var role: String?
    /// Its subrole, such as `AXStandardWindow` or `AXDialog`, or nil when it doesn't say yet.
    var subrole: String?
    /// Its title, or nil when it has none.
    var title: String?
    /// Whether it's modal.
    var isModal = false
    /// Whether it can be resized.
    var isResizable = true
    /// Whether it's in macOS's own fullscreen.
    var isFullScreen = false
}
