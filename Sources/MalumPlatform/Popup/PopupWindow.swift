import AppKit
import MalumCore

/// The popup's window: a frosted, rounded panel in the middle of the screen with a search field
/// and a list. It never activates Malum, so the app below stays in front, and a paste goes there.
@MainActor
final class PopupWindow: NSPanel {
    /// The search field.
    let field = NSTextField()
    /// The list's name, at the top right.
    let label = NSTextField(labelWithString: "")
    /// Clear all, for a list whose rows can be deleted.
    let clearButton = NSButton(title: PopupWords.clearAll, target: nil, action: nil)
    /// The rows.
    let table = NSTableView()

    /// Builds the panel with room for `rows` rows.
    init(rows: Int) {
        let size = PopupLayout.size(rows: rows)
        super.init(
            contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .modalPanel
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isMovable = false
        let background = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        background.material = .popover
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = PopupLayout.cornerRadius
        background.layer?.masksToBounds = true
        contentView = background
        addSearch(to: background)
        addList(to: background)
    }

    /// Not used: the panel is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// Takes the typing, though Malum never becomes the active app.
    override var canBecomeKey: Bool { true }

    /// Never the main window.
    override var canBecomeMain: Bool { false }

    /// Puts the panel in the middle of the main screen, its top a fifth of the way down.
    func place() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let area = screen.frame
        let left = area.minX + PopupLayout.middle(of: frame.width, in: area.width)
        let bottom = area.maxY - area.height * PopupLayout.topFraction - frame.height
        setFrameOrigin(NSPoint(x: left.rounded(), y: max(area.minY, bottom).rounded()))
    }

    /// The magnifying glass, the search field, the list's name and the clear button.
    private func addSearch(to view: NSView) {
        let bounds = view.bounds
        let iconTop = PopupLayout.middle(of: PopupLayout.iconSize, in: PopupLayout.searchHeight)
        let glass = NSImageView(
            frame: PopupLayout.frame(
                left: PopupLayout.margin, top: iconTop, size: PopupLayout.square(PopupLayout.iconSize), in: bounds))
        glass.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: PopupWords.search)
        glass.contentTintColor = .secondaryLabelColor
        view.addSubview(glass)
        let labelLeft = bounds.width - PopupLayout.margin - PopupLayout.labelWidth
        let buttonLeft = labelLeft - PopupLayout.buttonWidth
        field.frame = PopupLayout.frame(
            left: PopupLayout.textLeft, top: iconTop,
            size: NSSize(width: buttonLeft - PopupLayout.textLeft, height: PopupLayout.iconSize), in: bounds)
        field.font = .systemFont(ofSize: PopupLayout.searchFontSize, weight: .light)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.cell?.usesSingleLineMode = true
        view.addSubview(field)
        let smallTop = PopupLayout.middle(of: PopupLayout.smallSize, in: PopupLayout.searchHeight)
        label.frame = PopupLayout.frame(
            left: labelLeft, top: smallTop, size: NSSize(width: PopupLayout.labelWidth, height: PopupLayout.smallSize),
            in: bounds)
        label.font = .systemFont(ofSize: PopupLayout.smallFontSize, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.alignment = .right
        view.addSubview(label)
        clearButton.frame = PopupLayout.frame(
            left: buttonLeft, top: smallTop,
            size: NSSize(width: PopupLayout.buttonWidth, height: PopupLayout.smallSize), in: bounds)
        clearButton.bezelStyle = .inline
        clearButton.refusesFirstResponder = true
        view.addSubview(clearButton)
    }

    /// The scrolling list below the search field.
    private func addList(to view: NSView) {
        let height = view.bounds.height - PopupLayout.searchHeight
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: height))
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(PopupCell.identifier.rawValue))
        column.width = view.bounds.width
        table.addTableColumn(column)
        table.headerView = nil
        table.style = .plain
        table.rowHeight = PopupLayout.rowHeight
        table.intercellSpacing = .zero
        table.backgroundColor = .clear
        table.refusesFirstResponder = true
        scroll.documentView = table
        view.addSubview(scroll)
    }
}
