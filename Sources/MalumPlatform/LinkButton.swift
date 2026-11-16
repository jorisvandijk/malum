import AppKit

/// A web link: plain text in the accent colour, underlined while the pointer is over it, with the
/// pointing hand as its cursor.
@MainActor
final class LinkButton: NSButton {
    /// Creates a link showing `text` that calls `action` on `target` when clicked.
    init(_ text: String, target: AnyObject, action: Selector) {
        super.init(frame: .zero)
        self.target = target
        self.action = action
        isBordered = false
        title = text
        underline(false)
    }

    /// Not used: the link is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// The pointing hand over the whole link.
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    /// Follows the pointer over the link, for the underline.
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(
            NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    /// Underlines the link while the pointer is over it.
    override func mouseEntered(with event: NSEvent) {
        underline(true)
    }

    /// Takes the underline off when the pointer leaves.
    override func mouseExited(with event: NSEvent) {
        underline(false)
    }

    /// Draws the title in the accent colour, underlined when `isUnderlined`.
    private func underline(_ isUnderlined: Bool) {
        var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.controlAccentColor]
        if isUnderlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        attributedTitle = NSAttributedString(string: title, attributes: attributes)
    }
}
