import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// The window manager's words.
extension Message {
    /// Hiding the other apps left `apps` in view.
    static func couldntHide(_ apps: [String]) -> Message {
        couldnt("hide \(apps.joined(separator: ", "))", "macOS didn't hide them", level: .warn)
    }

    /// `app` didn't come to the front after its shortcut, however often it was asked.
    static func couldntRaise(_ app: String) -> Message {
        couldnt("bring \(app) to the front", "macOS kept another app in front", level: .warn)
    }

    /// The window titled `title` of `app` is now `kind`.
    static func window(_ title: String?, of app: String, is kind: WindowKind) -> Message {
        let window: MessageText =
            if let title { "\(app) window \"\(private: title)\"" } else { "\(app) window without a title" }
        switch kind {
        case .managed:
            return Message(.info, "\(window) fills its slot")
        case .float(let reason):
            return Message(.info, "\(window) floats: \(reason)")
        case .notReady:
            return Message(.info, "\(window) doesn't say what it is yet")
        }
    }

    /// `app` keeps changing its window's frame, so it's left at `size`.
    static func keepsResizing(_ app: String, _ size: CGSize) -> Message {
        Message(.warn, "\(app) keeps resizing its window, leaving it at \(Int(size.width))x\(Int(size.height))")
    }
}
