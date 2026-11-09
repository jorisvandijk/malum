/// What the window manager does with a window.
enum WindowKind: Equatable, Sendable {
    /// It fills its slot and snaps back when moved or resized.
    case managed
    /// It's left alone, for this reason.
    case float(FloatReason)
    /// It doesn't say what it is yet, so it's looked at again shortly.
    case notReady
}

/// Why a window is left alone.
enum FloatReason: Equatable, Sendable {
    /// A float rule in the settings matches it.
    case rule
    /// It isn't a window, but has this role, such as a sheet or a popover.
    case role(String)
    /// It has this subrole, such as `AXDialog` or `AXFloatingWindow`.
    case subrole(String)
    /// It's in macOS's own fullscreen.
    case fullScreen
    /// It's modal.
    case modal
    /// It can't be resized.
    case fixedSize
}
