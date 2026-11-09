import AppKit
import MalumCore

/// Draws a screenshot session over the frozen screen and turns mouse and keys into calls on it.
/// Its y grows down, the same as the session's points.
@MainActor
final class OverlayView: NSView {
    /// How wide the border that marks the frozen screen is.
    private static let borderWidth = 6.0
    /// Half, for a line that's stroked on a rectangle's edge.
    private static let half = 0.5
    /// How wide the selection's outline is.
    private static let selectionWidth = 1.5
    /// How long each dash of the selection's outline is.
    private static let dashLength = 6.0
    /// How long each gap of the selection's outline is.
    private static let gapLength = 4.0
    /// The selection outline's dashes.
    private static let selectionDash: [CGFloat] = [dashLength, gapLength]
    /// How much a scroll with cmd held zooms per point scrolled.
    private static let zoomPerScroll = 0.01

    /// The shot being edited.
    var session: ScreenshotSession
    /// What to do with each outcome other than a redraw.
    var onOutcome: (ScreenshotSession.Outcome) -> Void = { _ in }
    /// The frozen screen's pixels.
    private let image: NSImage
    /// The toolbar, built once the view exists so its clicks can reach it.
    private var toolbar: OverlayToolbar?

    /// Creates the view of `session` over `frozen`.
    init(frozen: any FrozenScreen, session: ScreenshotSession) {
        self.session = session
        image = NSImage(cgImage: frozen.image, size: frozen.screen.size)
        super.init(frame: CGRect(origin: .zero, size: frozen.frame.size))
        let toolbar = OverlayToolbar(quickColors: session.toolbar.quickColors) { [weak self] command in
            self?.perform(command)
        }
        addSubview(toolbar)
        self.toolbar = toolbar
        toolbar.show(session.toolbar, in: bounds)
    }

    /// Runs `command` from a toolbar button as its key would.
    private func perform(_ command: ScreenshotCommand) {
        if session.isTyping {
            _ = session.perform(.cancel)
        }
        handle(session.perform(command))
    }

    /// Takes `color` from the color picker for what's drawn next.
    func pick(_ color: ScreenshotColor) {
        handle(session.pick(color))
    }

    /// Not used: the view is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// The session's points grow down.
    override var isFlipped: Bool { true }

    /// Takes keys.
    override var acceptsFirstResponder: Bool { true }

    /// Draws the shown part with its annotations, the selection being dragged and the border.
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        NSColor.black.setFill()
        bounds.fill()
        let viewport = session.viewport
        context.saveGState()
        context.clip(to: viewport.shown)
        context.translateBy(x: viewport.shown.minX, y: viewport.shown.minY)
        context.scaleBy(x: viewport.scale, y: viewport.scale)
        context.translateBy(x: -viewport.crop.minX, y: -viewport.crop.minY)
        image.draw(
            in: session.edits.screen, from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: nil)
        AnnotationDrawing.draw(session.edits.annotations + [session.preview].compactMap { $0 }, in: context)
        context.restoreGState()
        drawSelection()
        drawBorder()
    }

    /// Outlines the part being selected.
    private func drawSelection() {
        guard let selection = session.selection else { return }
        let start = session.viewport.overlayPoint(at: selection.origin)
        let end = session.viewport.overlayPoint(at: CGPoint(x: selection.maxX, y: selection.maxY))
        let outline = NSBezierPath(rect: CGRect(corner: start, corner: end))
        outline.lineWidth = Self.selectionWidth
        outline.setLineDash(Self.selectionDash, count: Self.selectionDash.count, phase: 0)
        NSColor.white.setStroke()
        outline.stroke()
    }

    /// The border round the whole screen that says it's the frozen shot, not the live screen.
    private func drawBorder() {
        let inset = Self.borderWidth * Self.half
        let border = NSBezierPath(rect: bounds.insetBy(dx: inset, dy: inset))
        border.lineWidth = Self.borderWidth
        NSColor.controlAccentColor.setStroke()
        border.stroke()
    }

    /// Starts a drag or text.
    override func mouseDown(with event: NSEvent) {
        handle(session.press(at: point(of: event)))
    }

    /// Moves a drag.
    override func mouseDragged(with event: NSEvent) {
        handle(session.move(to: point(of: event)))
    }

    /// Ends a drag.
    override func mouseUp(with event: NSEvent) {
        handle(session.release(at: point(of: event)))
    }

    /// Scrolls the shown part, or zooms it with cmd held.
    override func scrollWheel(with event: NSEvent) {
        guard event.modifierFlags.contains(.command) else {
            handle(session.scroll(by: CGPoint(x: event.scrollingDeltaX, y: event.scrollingDeltaY)))
            return
        }
        handle(session.zoom(by: 1 + event.scrollingDeltaY * Self.zoomPerScroll, at: point(of: event)))
    }

    /// Zooms with a pinch.
    override func magnify(with event: NSEvent) {
        handle(session.zoom(by: 1 + event.magnification, at: point(of: event)))
    }

    /// Sends keys to the text being typed, or runs the overlay's key commands.
    override func keyDown(with event: NSEvent) {
        let modifiers = event.cgEvent.map { Modifier.held(in: $0.flags) } ?? []
        let command = ScreenshotKeys.command(keyCode: event.keyCode, modifiers: modifiers)
        guard !session.isTyping || ScreenshotKeys.worksWhileTyping(command) else {
            typeKey(event)
            return
        }
        guard let command else { return }
        handle(session.perform(command))
    }

    /// Types `event`'s characters, or deletes one for the delete key.
    private func typeKey(_ event: NSEvent) {
        guard !ScreenshotKeys.deletesBackward(keyCode: event.keyCode) else {
            handle(session.deleteBackward())
            return
        }
        handle(session.type(event.characters ?? ""))
    }

    /// Redraws or hands the outcome on.
    private func handle(_ outcome: ScreenshotSession.Outcome) {
        switch outcome {
        case .unchanged:
            return
        case .redraw:
            needsDisplay = true
            toolbar?.show(session.toolbar, in: bounds)
        case .openColorPicker, .save, .cancel:
            onOutcome(outcome)
        }
    }

    /// Where `event` happened in the view.
    private func point(of event: NSEvent) -> CGPoint {
        convert(event.locationInWindow, from: nil)
    }
}
