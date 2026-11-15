import AppKit
import MalumCore

/// One screen's part of the window picker: takes the click or esc, and shows the hint.
@MainActor
final class ClickView: NSView {
    /// How far the hint sits below the top of the screen.
    private static let hintTop = 80.0
    /// How big the hint's text is.
    private static let hintSize = 15.0
    /// How dark the hint's background is.
    private static let hintBackground = 0.6
    /// Halves a width, to centre the hint.
    private static let halves = 2.0

    /// Called with true for a click, false for esc.
    var onAnswer: (Bool) -> Void = { _ in }

    /// Creates the view, with the hint at the top when `showsHint`.
    init(frame: CGRect, showsHint: Bool) {
        super.init(frame: frame)
        guard showsHint else { return }
        let hint = NSTextField(labelWithString: InspectorWords.hint)
        hint.font = .systemFont(ofSize: Self.hintSize, weight: .medium)
        hint.textColor = .white
        hint.drawsBackground = true
        hint.backgroundColor = .black.withAlphaComponent(Self.hintBackground)
        hint.sizeToFit()
        hint.frame.origin = CGPoint(x: (frame.width - hint.frame.width) / Self.halves, y: frame.height - Self.hintTop)
        addSubview(hint)
    }

    /// Not used: the view is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// Takes the keys, for esc.
    override var acceptsFirstResponder: Bool { true }

    /// Takes the first click even though Malum isn't the active app.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// A click picks the window below.
    override func mouseDown(with event: NSEvent) {
        onAnswer(true)
    }

    /// Esc cancels; every other key is ignored.
    override func keyDown(with event: NSEvent) {
        guard event.keyCode == Key.escape?.keyCode else { return }
        onAnswer(false)
    }
}
