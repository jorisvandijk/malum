import AppKit
import MalumCore

/// The desktop picture of every screen, through `NSWorkspace`.
@MainActor
public struct WorkspaceDesktop {
    /// Creates the desktop.
    public init() {}
}

// MARK: - Desktop

extension WorkspaceDesktop: Desktop {
    /// The path of the picture each screen shows now, nil for a screen that shows none.
    public func pictures() -> [String?] {
        NSScreen.screens.map { NSWorkspace.shared.desktopImageURL(for: $0)?.path }
    }

    /// Shows the picture at `path` on every screen.
    public func show(_ path: String) throws {
        let picture = URL(fileURLWithPath: path)
        for screen in NSScreen.screens {
            try NSWorkspace.shared.setDesktopImageURL(picture, for: screen, options: [:])
        }
    }
}
