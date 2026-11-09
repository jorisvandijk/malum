import AppKit
import MalumCore

/// The screenshot toolbar: a row of frosted, rounded panels grouped by kind, each button with its
/// key underneath, centered at the top or bottom of the overlay.
@MainActor
final class OverlayToolbar: NSStackView {
    /// Space between the panels.
    private static let groupSpacing = 10.0
    /// Space between the buttons in a panel.
    private static let buttonSpacing = 4.0
    /// Space round the buttons inside a panel.
    private static let padding = 6.0
    /// How round a panel's corners are.
    private static let cornerRadius = 12.0
    /// Half, for centering and round buttons.
    private static let half = 0.5
    /// How far the toolbar stays from the screen's edge.
    private static let margin = 24.0
    /// A button's size.
    private static let buttonSize = 28.0
    /// A quick color's dot inside its button.
    private static let swatchSize = 16.0
    /// How thick the ring round a picked button is.
    private static let ringWidth = 2.0
    /// The size of the key labels.
    private static let keyFontSize = 9.0
    /// What the line-width dot adds to the line's width, so the thinnest still shows.
    private static let lineSampleBase = 4.0
    /// How big the text-size letter is against the text it stands for.
    private static let textSampleScale = 0.5
    /// Each command's SF Symbol, for the buttons that aren't a quick color.
    private static let symbols: [ScreenshotCommand: String] = [
        .tool(.select): "crop", .zoomIn: "plus.magnifyingglass", .zoomOut: "minus.magnifyingglass",
        .tool(.line): "line.diagonal", .tool(.arrow): "arrow.up.right", .tool(.rectangle): "rectangle",
        .tool(.text): "textformat", .colorPicker: "eyedropper", .smaller: "minus", .larger: "plus",
        .undo: "arrow.uturn.backward", .redo: "arrow.uturn.forward", .moveToolbar: "arrow.up.and.down",
        .cancel: "xmark", .save: "checkmark",
    ]

    /// What a click on a button asks for.
    private let onCommand: (ScreenshotCommand) -> Void
    /// The quick colors, for their dots.
    private let quickColors: [ScreenshotColor]
    /// Every button by its command, to show which is picked.
    private var buttons: [ScreenshotCommand: NSButton] = [:]
    /// Shows the current size between the size buttons.
    private let currentSize = NSTextField(labelWithString: "")

    /// Builds the toolbar with `quickColors`, sending each click's command to `onCommand`.
    init(quickColors: [ScreenshotColor], onCommand: @escaping (ScreenshotCommand) -> Void) {
        self.onCommand = onCommand
        self.quickColors = quickColors
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = Self.groupSpacing
        for group in ToolbarLayout.groups(quickColors: quickColors.count) {
            addArrangedSubview(panel(of: group))
        }
    }

    /// Not used: the toolbar is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// Shows what `toolbar` has picked, and puts the bar at the top or bottom of `bounds`.
    func show(_ toolbar: ScreenshotToolbar, in bounds: CGRect) {
        for (command, button) in buttons {
            button.layer?.borderWidth = ToolbarLayout.isPicked(command, in: toolbar) ? Self.ringWidth : 0
        }
        let isText = toolbar.tool == .text
        let sample = isText ? ScreenshotWords.textSample : ScreenshotWords.lineSample
        let lineSample = toolbar.size.lineWidth + Self.lineSampleBase
        let textSample = toolbar.size.textSize * Self.textSampleScale
        currentSize.stringValue = sample
        currentSize.font = .systemFont(ofSize: isText ? textSample : lineSample)
        currentSize.textColor = NSColor(cgColor: toolbar.color.cgColor)
        let size = fittingSize
        let top = bounds.minY + Self.margin
        let bottom = bounds.maxY - Self.margin - size.height
        frame = CGRect(
            origin: CGPoint(x: bounds.midX - size.width * Self.half, y: toolbar.isAtBottom ? bottom : top), size: size)
    }

    /// One frosted panel with the items of `group`.
    private func panel(of group: [ToolbarItem]) -> NSView {
        let background = NSVisualEffectView()
        background.material = .popover
        background.blendingMode = .withinWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = Self.cornerRadius
        background.layer?.masksToBounds = true
        let row = NSStackView(views: group.map(view(of:)))
        row.orientation = .horizontal
        row.spacing = Self.buttonSpacing
        row.edgeInsets = NSEdgeInsets(top: Self.padding, left: Self.padding, bottom: Self.padding, right: Self.padding)
        row.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            row.topAnchor.constraint(equalTo: background.topAnchor),
            row.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
        return background
    }

    /// One item: a button with its key underneath, or the current size.
    private func view(of item: ToolbarItem) -> NSView {
        guard case .button(let command) = item else { return currentSize }
        let button = NSButton(image: image(for: command), target: self, action: #selector(clicked(_:)))
        button.isBordered = false
        button.toolTip = ScreenshotWords.name(of: command)
        button.wantsLayer = true
        button.layer?.cornerRadius = Self.buttonSize * Self.half
        button.layer?.borderColor = NSColor.controlAccentColor.cgColor
        button.widthAnchor.constraint(equalToConstant: Self.buttonSize).isActive = true
        button.heightAnchor.constraint(equalToConstant: Self.buttonSize).isActive = true
        buttons[command] = button
        let key = NSTextField(labelWithString: ToolbarLayout.keyLabel(of: command))
        key.font = .systemFont(ofSize: Self.keyFontSize)
        key.textColor = .secondaryLabelColor
        let column = NSStackView(views: [button, key])
        column.orientation = .vertical
        column.spacing = 0
        return column
    }

    /// The picture on `command`'s button: a quick color's dot or the command's symbol.
    private func image(for command: ScreenshotCommand) -> NSImage {
        guard case .quickColor(let index) = command, quickColors.indices.contains(index) else {
            let symbol = Self.symbols[command] ?? ""
            return NSImage(systemSymbolName: symbol, accessibilityDescription: ScreenshotWords.name(of: command))
                ?? NSImage()
        }
        let color = NSColor(cgColor: quickColors[index].cgColor) ?? .white
        let size = NSSize(width: Self.swatchSize, height: Self.swatchSize)
        return NSImage(size: size, flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
    }

    /// Sends the clicked button's command.
    @objc private func clicked(_ sender: NSButton) {
        guard let command = buttons.first(where: { $0.value === sender })?.key else { return }
        onCommand(command)
    }
}
