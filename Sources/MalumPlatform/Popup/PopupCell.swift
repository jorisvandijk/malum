import AppKit
import MalumCore

/// One row's contents: an icon, the title, and on lists that can be deleted from, the detail and
/// a delete button.
@MainActor
final class PopupCell: NSTableCellView {
    /// The id AppKit reuses cells by.
    static let identifier = NSUserInterfaceItemIdentifier("PopupCell")

    /// Short text on the right.
    private let detail = NSTextField(labelWithString: "")
    /// Deletes the row.
    let deleteButton = NSButton()
    /// Whether the row can be deleted.
    var canDelete = false {
        didSet { updateDelete() }
    }
    /// Whether the row is selected or hovered, which shows the delete button.
    var showsDelete = false {
        didSet { updateDelete() }
    }

    /// Builds an empty cell.
    init() {
        let size = NSSize(width: PopupLayout.width, height: PopupLayout.rowHeight)
        super.init(frame: NSRect(origin: .zero, size: size))
        identifier = Self.identifier
        let bounds = NSRect(origin: .zero, size: size)
        let iconTop = PopupLayout.middle(of: PopupLayout.iconSize, in: PopupLayout.rowHeight)
        let icon = NSImageView(
            frame: PopupLayout.frame(
                left: PopupLayout.margin, top: iconTop, size: PopupLayout.square(PopupLayout.iconSize), in: bounds))
        icon.imageScaling = .scaleProportionallyUpOrDown
        addSubview(icon)
        imageView = icon
        addTexts(in: bounds)
        updateDelete()
    }

    /// The title, the detail and the delete button, left to right.
    private func addTexts(in bounds: NSRect) {
        let top = PopupLayout.middle(of: PopupLayout.smallSize, in: PopupLayout.rowHeight)
        let buttonLeft = bounds.width - PopupLayout.margin - PopupLayout.smallSize
        let detailLeft = buttonLeft - PopupLayout.labelWidth
        let title = NSTextField(labelWithString: "")
        title.frame = PopupLayout.frame(
            left: PopupLayout.textLeft, top: top,
            size: NSSize(width: detailLeft - PopupLayout.textLeft, height: PopupLayout.smallSize), in: bounds)
        title.font = .systemFont(ofSize: PopupLayout.titleFontSize)
        title.lineBreakMode = .byTruncatingTail
        addSubview(title)
        textField = title
        detail.frame = PopupLayout.frame(
            left: detailLeft, top: top,
            size: NSSize(width: PopupLayout.labelWidth - PopupLayout.margin, height: PopupLayout.smallSize), in: bounds)
        detail.font = .systemFont(ofSize: PopupLayout.smallFontSize)
        detail.textColor = .secondaryLabelColor
        detail.alignment = .right
        addSubview(detail)
        deleteButton.frame = PopupLayout.frame(
            left: buttonLeft, top: top, size: PopupLayout.square(PopupLayout.smallSize), in: bounds)
        deleteButton.isBordered = false
        deleteButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: PopupWords.delete)
        deleteButton.contentTintColor = .secondaryLabelColor
        deleteButton.refusesFirstResponder = true
        deleteButton.toolTip = PopupWords.delete
        addSubview(deleteButton)
    }

    /// Not used: cells are only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// Fills the cell with `row` and its `icon`.
    func show(_ row: PopupRow, icon: NSImage?) {
        textField?.stringValue = row.title
        detail.stringValue = row.detail ?? ""
        imageView?.image = icon
    }

    /// Shows the delete button only on a row that can be deleted and is selected or hovered.
    private func updateDelete() {
        deleteButton.isHidden = !(canDelete && showsDelete)
    }
}
