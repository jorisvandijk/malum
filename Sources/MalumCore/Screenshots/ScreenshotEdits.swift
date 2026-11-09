import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// What has been done to one frozen screen: the part kept and what's drawn on it, with undo and redo.
/// Everything is in the frozen screen's points, so a crop never moves what's drawn.
public struct ScreenshotEdits: Equatable, Sendable {
    /// One step that undo takes back.
    private enum Edit: Equatable, Sendable {
        /// An annotation was added.
        case add(Annotation)
        /// The part kept changed from one rectangle to another.
        case crop(from: CGRect, to: CGRect)
    }

    /// The whole frozen screen.
    public let screen: CGRect
    /// The part of the screen kept, the whole screen until a selection is made.
    public private(set) var crop: CGRect
    /// What's drawn, oldest first.
    public private(set) var annotations: [Annotation] = []
    /// The steps undo takes back, latest last.
    private var done: [Edit] = []
    /// The steps redo puts back, latest undone last.
    private var undone: [Edit] = []

    /// Creates the edits of a frozen screen as big as `screen`, with nothing done yet.
    public init(screen: CGRect) {
        self.screen = screen
        crop = screen
    }

    /// Whether anything is drawn, so the annotated file is saved too.
    public var isAnnotated: Bool { !annotations.isEmpty }

    /// Whether there's a step to undo.
    public var canUndo: Bool { !done.isEmpty }

    /// Whether there's a step to redo.
    public var canRedo: Bool { !undone.isEmpty }

    /// Draws `annotation`. Redo starts over.
    public mutating func add(_ annotation: Annotation) {
        record(.add(annotation))
    }

    /// Keeps `selection`, clipped to the screen. An empty or outside selection does nothing.
    public mutating func select(_ selection: CGRect) {
        let kept = selection.intersection(screen)
        guard !kept.isNull, !kept.isEmpty, kept != crop else { return }
        record(.crop(from: crop, to: kept))
    }

    /// Takes back the latest step.
    public mutating func undo() {
        guard let edit = done.popLast() else { return }
        switch edit {
        case .add:
            annotations.removeLast()
        case .crop(let from, _):
            crop = from
        }
        undone.append(edit)
    }

    /// Puts back the latest undone step.
    public mutating func redo() {
        guard let edit = undone.popLast() else { return }
        apply(edit)
        done.append(edit)
    }

    /// Does `edit` as a new step, which clears redo.
    private mutating func record(_ edit: Edit) {
        apply(edit)
        done.append(edit)
        undone.removeAll()
    }

    /// Does `edit`.
    private mutating func apply(_ edit: Edit) {
        switch edit {
        case .add(let annotation):
            annotations.append(annotation)
        case .crop(_, let to):
            crop = to
        }
    }
}
