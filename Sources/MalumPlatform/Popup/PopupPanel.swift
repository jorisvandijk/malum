import AppKit
import MalumCore

/// The real popup: shows what `PopupCenter` gives it in a `PopupWindow`, and passes typing, keys
/// and clicks back as `PopupEvent`s.
@MainActor
public final class PopupPanel: NSObject, Popup {
    /// Where the events go.
    public var onEvent: (@MainActor (PopupEvent) -> Void)?
    /// The window, built the first time the popup opens.
    private var window: PopupWindow?
    /// What it shows.
    private var content = PopupContent.empty
    /// The pictures shown so far, until the popup closes.
    private var icons: [PopupIcon: NSImage] = [:]
    /// Whether clear all was clicked once and waits for the second click.
    private var clearArmed = false {
        didSet { window?.clearButton.title = clearArmed ? PopupWords.confirmClear : PopupWords.clearAll }
    }

    /// Creates the popup, which builds its window when it first opens.
    override public init() {
        super.init()
    }

    /// Whether it's on screen.
    public var isOpen: Bool { window?.isVisible ?? false }

    /// Shows it in the middle of the screen with an empty search field and the typing.
    public func open(_ content: PopupContent) {
        let window = self.window ?? makeWindow()
        self.window = window
        window.field.stringValue = ""
        show(content)
        window.place()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.field)
    }

    /// Shows new rows, keeping the search text.
    public func show(_ content: PopupContent) {
        self.content = content
        guard let window else { return }
        window.field.placeholderString = content.placeholder
        window.label.stringValue = content.label
        window.clearButton.isHidden = !content.canDelete
        window.table.reloadData()
        guard let selection = content.selection else {
            window.table.deselectAll(nil)
            return
        }
        window.table.selectRowIndexes(IndexSet(integer: selection), byExtendingSelection: false)
        window.table.scrollRowToVisible(selection)
    }

    /// Takes it off screen.
    public func close() {
        clearArmed = false
        icons = [:]
        window?.orderOut(nil)
    }

    /// Builds the window and connects it.
    private func makeWindow() -> PopupWindow {
        let window = PopupWindow(rows: PopupCenter.visibleRows)
        window.field.delegate = self
        window.table.dataSource = self
        window.table.delegate = self
        window.table.target = self
        window.table.action = #selector(clicked)
        window.clearButton.target = self
        window.clearButton.action = #selector(clearClicked)
        NotificationCenter.default.addObserver(
            self, selector: #selector(lostTyping), name: NSWindow.didResignKeyNotification, object: window)
        return window
    }

    /// Passes `event` on, and forgets a first click on clear all.
    private func send(_ event: PopupEvent) {
        if event != .clearAll { clearArmed = false }
        onEvent?(event)
    }

    /// A click elsewhere took the typing away: closes, as Spotlight does.
    @objc private func lostTyping() {
        guard isOpen else { return }
        close()
        send(.closed)
    }

    /// A row was clicked.
    @objc private func clicked() {
        guard let row = window?.table.clickedRow, row >= 0 else { return }
        send(.clicked(row))
    }

    /// A row's delete button was clicked; its tag is the row.
    @objc private func deleteClicked(_ sender: NSButton) {
        send(.deleteClicked(sender.tag))
    }

    /// Clear all was clicked: the first click asks for a second.
    @objc private func clearClicked() {
        guard clearArmed else {
            clearArmed = true
            return
        }
        clearArmed = false
        send(.clearAll)
    }

    /// The picture for `icon`, kept until the popup closes.
    private func image(for icon: PopupIcon) -> NSImage? {
        if let known = icons[icon] { return known }
        let made: NSImage?
        switch icon {
        case .none:
            made = nil
        case .file(let path):
            made = NSWorkspace.shared.icon(forFile: path)
        case .image(let path):
            made = NSImage(contentsOfFile: path)
        }
        icons[icon] = made
        return made
    }
}

// MARK: - NSTextFieldDelegate

extension PopupPanel: NSTextFieldDelegate {
    /// The search text changed.
    public func controlTextDidChange(_ obj: Notification) {
        send(.query(window?.field.stringValue ?? ""))
    }

    /// Turns the keys the popup knows into commands; ctrl+n and ctrl+p arrive as down and up.
    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let command = Self.commands[commandSelector] else { return false }
        send(.command(command))
        return true
    }

    /// The text field commands the popup handles.
    private static let commands: [Selector: PopupCommand] = [
        #selector(NSResponder.moveDown(_:)): .down,
        #selector(NSResponder.moveUp(_:)): .up,
        #selector(NSResponder.pageDown(_:)): .pageDown,
        #selector(NSResponder.scrollPageDown(_:)): .pageDown,
        #selector(NSResponder.pageUp(_:)): .pageUp,
        #selector(NSResponder.scrollPageUp(_:)): .pageUp,
        #selector(NSResponder.insertNewline(_:)): .choose,
        #selector(NSResponder.cancelOperation(_:)): .close,
        #selector(NSResponder.insertTab(_:)): .switchList,
        #selector(NSResponder.insertBacktab(_:)): .switchList,
        #selector(NSResponder.deleteToBeginningOfLine(_:)): .delete,
    ]
}

// MARK: - NSTableViewDataSource

extension PopupPanel: NSTableViewDataSource {
    /// How many rows there are.
    public func numberOfRows(in tableView: NSTableView) -> Int {
        content.rows.count
    }
}

// MARK: - NSTableViewDelegate

extension PopupPanel: NSTableViewDelegate {
    /// The cell for row `row`.
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard content.rows.indices.contains(row) else { return nil }
        let reused = tableView.makeView(withIdentifier: PopupCell.identifier, owner: self) as? PopupCell
        let cell = reused ?? PopupCell()
        let shown = content.rows[row]
        cell.show(shown, icon: image(for: shown.icon))
        cell.canDelete = content.canDelete
        cell.deleteButton.tag = row
        cell.deleteButton.target = self
        cell.deleteButton.action = #selector(deleteClicked(_:))
        return cell
    }

    /// The row view, which draws the selection.
    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        PopupRowView()
    }
}
