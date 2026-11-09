import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// The decisions behind filling the screen, apart from Accessibility so they're tested on Linux.
enum WindowLayout {
    /// The role of a window.
    static let windowRole = "AXWindow"
    /// The subrole of an ordinary window.
    static let standardSubrole = "AXStandardWindow"
    /// The subrole a window has before it says what it is.
    static let unknownSubrole = "AXUnknown"
    /// How far apart two frames may be and still count as the same, since apps round their sizes.
    static let tolerance: CGFloat = 1
    /// The left slot takes half the area when there's more than one window.
    private static let halves: CGFloat = 2

    /// What to do with the window `facts` describes, of the app `app`, with `floats` from the settings.
    /// Ordinary windows are managed. Dialogs, panels, modals, fixed-size and fullscreen windows, and
    /// those a float rule matches, float.
    static func classify(_ facts: WindowFacts, app: String?, floats: [FloatRule]) -> WindowKind {
        if floats.contains(where: { $0.matches(app: app, title: facts.title) }) {
            return .float(.rule)
        }
        guard let role = facts.role else { return .notReady }
        guard role == windowRole else { return .float(.role(role)) }
        guard !facts.isFullScreen else { return .float(.fullScreen) }
        guard let subrole = facts.subrole, subrole != unknownSubrole else { return .notReady }
        guard subrole == standardSubrole else { return .float(.subrole(subrole)) }
        guard !facts.isModal else { return .float(.modal) }
        guard facts.isResizable else { return .float(.fixedSize) }
        return .managed
    }

    /// Where each of an app's `count` managed windows goes in `area`, oldest first. One fills the
    /// area, two split it left and right, and from three on the oldest keeps the left half while the
    /// rest stack on the right.
    static func slots(count: Int, in area: CGRect) -> [CGRect] {
        guard count > 1 else { return count == 1 ? [area.integral] : [] }
        let leftWidth = (area.width / halves).rounded(.down)
        let right = area.minX + leftWidth
        let stacked = count - 1
        let rows = (0...stacked).map { area.minY + (area.height * CGFloat($0) / CGFloat(stacked)).rounded(.down) }
        let rightSlots = (0..<stacked).map { row in
            let bottom = row == stacked - 1 ? area.maxY : rows[row + 1]
            return CGRect(x: right, y: rows[row], width: area.maxX - right, height: bottom - rows[row])
        }
        return [CGRect(x: area.minX, y: area.minY, width: leftWidth, height: area.height)] + rightSlots
    }

    /// Where a window that settled at `size` goes in `slot`: one that won't grow to fill it is
    /// centred, one that won't shrink to fit is pinned to the slot's top left.
    static func place(_ size: CGSize, in slot: CGRect) -> CGPoint {
        CGPoint(x: start(size.width, in: slot.minX, slot.width), y: start(size.height, in: slot.minY, slot.height))
    }

    /// Whether `first` and `second` are within `tolerance` of each other on every side.
    static func isSame(_ first: CGRect, _ second: CGRect) -> Bool {
        abs(first.minX - second.minX) <= tolerance && abs(first.minY - second.minY) <= tolerance
            && abs(first.width - second.width) <= tolerance && abs(first.height - second.height) <= tolerance
    }

    /// Which of `slots` a window dropped with the pointer at `point` lands in, other than `from`, its
    /// own, or nil when it's let go anywhere else.
    static func dropTarget(at point: CGPoint, slots: [CGRect], from: Int) -> Int? {
        slots.indices.first { $0 != from && slots[$0].contains(point) }
    }

    /// `rect` in AppKit's coordinates (from the bottom left of the main screen, going up) in
    /// Accessibility's (from the top left, going down), on a main screen `height` high.
    static func toAccessibility(_ rect: CGRect, mainScreenHeight height: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: height - rect.maxY, width: rect.width, height: rect.height)
    }

    /// Where a window `length` long starts along a slot that starts at `origin` and is `room` long:
    /// centred when it's shorter, at the start when it isn't.
    private static func start(_ length: CGFloat, in origin: CGFloat, _ room: CGFloat) -> CGFloat {
        guard length < room else { return origin }
        return origin + ((room - length) / halves).rounded(.down)
    }
}
