import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// One screenshot from freeze to save: what's done to the shot, how it's shown, the toolbar, and
/// the drag or text in progress. The overlay only turns mouse, keys and buttons into calls here
/// and draws what it holds; every decision is made here, where Linux tests reach it.
public struct ScreenshotSession: Equatable, Sendable {
    /// What the overlay should do after a call.
    public enum Outcome: Equatable, Sendable {
        /// Nothing changed.
        case unchanged
        /// Something changed, so draw again.
        case redraw
        /// Open macOS's color picker.
        case openColorPicker
        /// Save the shot and close.
        case save
        /// Close without saving.
        case cancel
    }

    /// A drag in progress, in shot points.
    public struct Drag: Equatable, Sendable {
        /// Where the mouse went down.
        public let start: CGPoint
        /// Where the mouse is now.
        public var end: CGPoint
    }

    /// Text being typed, before it becomes an annotation.
    public struct Typing: Equatable, Sendable {
        /// Where the text's first line starts, in shot points.
        public let origin: CGPoint
        /// The text so far.
        public var text: String
    }

    /// The crop and the annotations, with undo.
    public private(set) var edits: ScreenshotEdits
    /// How the kept part is shown.
    public private(set) var viewport: ScreenshotViewport
    /// The tool, color, size and bar position.
    public private(set) var toolbar: ScreenshotToolbar
    /// The drag in progress, if any.
    public private(set) var drag: Drag?
    /// The text being typed, if any.
    public private(set) var typing: Typing?

    /// Starts the session of a frozen `screen` with the quick colors from the settings.
    public init(screen: CGRect, quickColors: [ScreenshotColor]) {
        edits = ScreenshotEdits(screen: screen)
        viewport = ScreenshotViewport(screen: screen)
        toolbar = ScreenshotToolbar(quickColors: quickColors)
    }

    /// Whether keys go to the text being typed.
    public var isTyping: Bool { typing != nil }

    /// What's being drawn but isn't an annotation yet: the shape of a drag, or the text being typed.
    public var preview: Annotation? {
        if let typing {
            return Annotation(.text(typing.text, at: typing.origin), color: toolbar.color, size: toolbar.size)
        }
        guard let drag, let shape = Annotation.dragged(toolbar.tool, from: drag.start, to: drag.end) else { return nil }
        return Annotation(shape, color: toolbar.color, size: toolbar.size)
    }

    /// The part being selected, in shot points, while the select tool is dragged.
    public var selection: CGRect? {
        guard let drag, toolbar.tool == .select else { return nil }
        return CGRect(corner: drag.start, corner: drag.end)
    }

    /// The mouse went down at `point` of the overlay: ends text being typed, or starts text or a drag.
    public mutating func press(at point: CGPoint) -> Outcome {
        guard !finishTyping() else { return .redraw }
        let shotPoint = viewport.shotPoint(at: point)
        if toolbar.tool == .text {
            typing = Typing(origin: shotPoint, text: "")
        } else {
            drag = Drag(start: shotPoint, end: shotPoint)
        }
        return .redraw
    }

    /// The mouse moved to `point` of the overlay with its button down.
    public mutating func move(to point: CGPoint) -> Outcome {
        guard drag != nil else { return .unchanged }
        drag?.end = viewport.shotPoint(at: point)
        return .redraw
    }

    /// The mouse went up at `point` of the overlay: a selection crops, a shape is drawn.
    public mutating func release(at point: CGPoint) -> Outcome {
        guard let start = drag?.start else { return .unchanged }
        let end = viewport.shotPoint(at: point)
        drag = nil
        guard toolbar.tool != .select else {
            edits.select(CGRect(corner: start, corner: end))
            viewport.show(edits.crop)
            return .redraw
        }
        if let shape = Annotation.dragged(toolbar.tool, from: start, to: end) {
            edits.add(Annotation(shape, color: toolbar.color, size: toolbar.size))
        }
        return .redraw
    }

    /// Carries out `command` from a key or a toolbar button. Enter and Escape end text being typed
    /// first; Enter then saves.
    public mutating func perform(_ command: ScreenshotCommand) -> Outcome {
        if isTyping, command == .save || command == .cancel {
            _ = finishTyping()
            guard command == .save else { return .redraw }
        }
        switch command {
        case .save:
            return .save
        case .cancel:
            return .cancel
        case .colorPicker:
            return .openColorPicker
        case .undo, .redo, .zoomIn, .zoomOut, .resetZoom:
            changeView(command)
            return .redraw
        case .tool, .quickColor, .smaller, .larger, .moveToolbar:
            return toolbar.perform(command) ? .redraw : .unchanged
        }
    }

    /// Adds `characters` to the text being typed.
    public mutating func type(_ characters: String) -> Outcome {
        guard typing != nil else { return .unchanged }
        typing?.text += characters
        return .redraw
    }

    /// Removes the last character of the text being typed.
    public mutating func deleteBackward() -> Outcome {
        guard let text = typing?.text, !text.isEmpty else { return .unchanged }
        typing?.text.removeLast()
        return .redraw
    }

    /// Takes `color` from macOS's color picker for what's drawn next.
    public mutating func pick(_ color: ScreenshotColor) -> Outcome {
        toolbar.color = color
        return .redraw
    }

    /// Zooms by `factor` around `point` of the overlay, from a pinch or a scroll with a modifier.
    public mutating func zoom(by factor: Double, at point: CGPoint) -> Outcome {
        viewport.zoom(by: factor, at: point)
        return .redraw
    }

    /// Moves the shown part by `offset`, from a scroll.
    public mutating func scroll(by offset: CGPoint) -> Outcome {
        viewport.move(by: offset)
        return .redraw
    }

    /// Carries out undo, redo and zoom. A crop that undo or redo changes is shown afresh.
    private mutating func changeView(_ command: ScreenshotCommand) {
        let crop = edits.crop
        switch command {
        case .undo:
            edits.undo()
        case .redo:
            edits.redo()
        case .zoomIn:
            viewport.zoomIn()
        case .zoomOut:
            viewport.zoomOut()
        case .resetZoom:
            viewport.reset()
        default:
            return
        }
        if edits.crop != crop {
            viewport.show(edits.crop)
        }
    }

    /// Turns the text being typed into an annotation, unless it's empty, and says whether there was
    /// text being typed.
    private mutating func finishTyping() -> Bool {
        guard let finished = typing else { return false }
        typing = nil
        if !finished.text.isEmpty {
            edits.add(Annotation(.text(finished.text, at: finished.origin), color: toolbar.color, size: toolbar.size))
        }
        return true
    }
}
