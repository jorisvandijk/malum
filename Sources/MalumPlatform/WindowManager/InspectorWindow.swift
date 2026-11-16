import AppKit
import MalumCore

/// The real inspector panel: a small floating window with one row per line of the report and a
/// Copy button. It shows without making Malum the active app, and esc or its close button shuts it.
@MainActor
public final class InspectorWindow: NSPanel {
    /// The room between the rows and the button.
    private static let buttonGap = 24.0
    /// The room between a row's label and its value.
    private static let columnGap = 16.0
    /// The room between rows.
    private static let rowGap = 8.0
    /// The widest a value gets before it wraps.
    private static let valueWidth = 420.0

    /// Called when Copy is clicked.
    private var onCopy: @MainActor () -> Void = {}

    /// Creates the panel, hidden.
    public init() {
        super.init(
            contentRect: .zero, styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered, defer: true)
        title = InspectorWords.title
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }

    /// Not used: the panel is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// Takes the keys, for esc and cmd+C in the values.
    override public var canBecomeKey: Bool { true }

    /// Esc closes the panel.
    override public func cancelOperation(_ sender: Any?) {
        close()
    }

    /// Puts the report on the clipboard.
    @objc private func copyReport() {
        onCopy()
    }

    /// The rows of `lines`, labels on the left, values on the right and selectable.
    private static func grid(of lines: [InspectorLine]) -> NSGridView {
        let rows = lines.map { line in
            let label = NSTextField(labelWithString: line.label)
            label.textColor = .secondaryLabelColor
            let value = NSTextField(wrappingLabelWithString: line.value)
            value.isSelectable = true
            value.preferredMaxLayoutWidth = valueWidth
            return [label, value]
        }
        let grid = NSGridView(views: rows)
        grid.columnSpacing = columnGap
        grid.rowSpacing = rowGap
        grid.column(at: 0).xPlacement = .trailing
        return grid
    }
}

// MARK: - InspectorPanel

extension InspectorWindow: InspectorPanel {
    /// Shows `lines` with a Copy button that calls `onCopy`, near the middle of the screen.
    public func show(_ lines: [InspectorLine], onCopy: @escaping @MainActor () -> Void) {
        self.onCopy = onCopy
        let button = NSButton(title: InspectorWords.copy, target: self, action: #selector(copyReport))
        button.keyEquivalent = "\r"
        let stack = NSStackView(views: [Self.grid(of: lines), button])
        stack.orientation = .vertical
        stack.alignment = .trailing
        stack.spacing = Self.buttonGap
        let margin = PanelLayout.margin
        stack.edgeInsets = NSEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        contentView = stack
        setContentSize(stack.fittingSize)
        center()
        makeKeyAndOrderFront(nil)
    }
}
