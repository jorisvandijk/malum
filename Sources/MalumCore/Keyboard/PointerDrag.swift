import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// The pointer's main button going down, moving while it's held, or going up, as the event tap
/// sees it. With the hyper key held, the tap hands the whole drag to the module that takes drags.
public struct PointerDrag: Equatable, Sendable {
    /// Where in the drag it is.
    public enum Phase: Equatable, Sendable {
        /// The button went down.
        case began
        /// The pointer moved with the button held.
        case moved
        /// The button went up.
        case ended
    }

    /// Where in the drag it is.
    let phase: Phase
    /// Where the pointer is, in Accessibility's coordinates (from the top left of the main screen).
    let location: CGPoint

    /// The drag at `phase`, with the pointer at `location`.
    public init(_ phase: Phase, at location: CGPoint) {
        self.phase = phase
        self.location = location
    }
}
