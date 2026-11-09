import AppKit

/// A popup row with a rounded selection in the accent colour, drawn as selected though the list
/// never has the typing. Its delete button shows while it's selected or under the pointer.
@MainActor
final class PopupRowView: NSTableRowView {
    /// The tracking that tells when the pointer is over the row.
    private var tracking: NSTrackingArea?
    /// Whether the pointer is over the row.
    private var isHovered = false {
        didSet { updateCell() }
    }

    /// Always drawn as if the list had the focus.
    override var isEmphasized: Bool {
        get { true }
        set { _ = newValue }
    }

    /// Shows or hides the delete button with the selection.
    override var isSelected: Bool {
        didSet { updateCell() }
    }

    /// Draws the rounded selection.
    override func drawSelection(in dirtyRect: NSRect) {
        NSColor.selectedContentBackgroundColor.setFill()
        let shape = bounds.insetBy(dx: PopupLayout.selectionInsetAcross, dy: PopupLayout.selectionInsetDown)
        NSBezierPath(roundedRect: shape, xRadius: PopupLayout.selectionRadius, yRadius: PopupLayout.selectionRadius)
            .fill()
    }

    /// Watches the pointer, also while Malum isn't the active app, which it never is here.
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(
            rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area)
        tracking = area
    }

    /// The pointer came over the row.
    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    /// The pointer left the row.
    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    /// Shows the cell's delete button while the row is selected or hovered.
    private func updateCell() {
        // Not view(atColumn:): AppKit sets isSelected before the cell is added.
        for case let cell as PopupCell in subviews {
            cell.showsDelete = isHovered || isSelected
        }
    }
}
