/// What Accessibility says about a window, everything `WindowLayout.classify` looks at.
public struct WindowFacts: Equatable, Sendable {
    /// Its role, such as `AXWindow`, or nil when it doesn't say yet.
    public var role: String?
    /// Its subrole, such as `AXStandardWindow` or `AXDialog`, or nil when it doesn't say yet.
    public var subrole: String?
    /// Its title, or nil when it has none.
    public var title: String?
    /// Whether it's modal.
    public var isModal: Bool
    /// Whether it can be resized.
    public var isResizable: Bool
    /// Whether it's in macOS's own fullscreen.
    public var isFullScreen: Bool

    /// Creates the facts of a window, by default an ordinary one that says nothing yet.
    public init(
        role: String? = nil, subrole: String? = nil, title: String? = nil, isModal: Bool = false,
        isResizable: Bool = true, isFullScreen: Bool = false
    ) {
        self.role = role
        self.subrole = subrole
        self.title = title
        self.isModal = isModal
        self.isResizable = isResizable
        self.isFullScreen = isFullScreen
    }
}
