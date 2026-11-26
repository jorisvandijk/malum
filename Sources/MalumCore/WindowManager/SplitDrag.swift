import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// A drag with the hyper key held that moves the borders between an app's windows: sideways the
/// one between the left column and the rest, and, when it starts in the right column, up or down
/// the border between two rows nearest the pointer. No exact hit on a border is needed.
///
/// Every split it gives is worked out from where the drag started, so the borders follow the
/// pointer without drifting, within the same limits as the split keys.
struct SplitDrag: Equatable, Sendable {
    /// Where the drag started.
    private let start: CGPoint
    /// How the area was shared out when it started.
    private let startSplit: Split
    /// The area the windows fill.
    private let area: CGRect
    /// How many rows the right column has.
    private let rows: Int
    /// The border below this row moves up and down, or none when the drag started in the left column
    /// or the right one has a single row.
    private let border: Int?

    /// A drag starting at `point` over `count` managed windows in `area`, shared out by `split`, or
    /// nil when there's a single window and so no border to move.
    init?(at point: CGPoint, in area: CGRect, split: Split, count: Int) {
        guard count > 1, area.width > 0, area.height > 0 else { return nil }
        start = point
        startSplit = split
        self.area = area
        rows = count - 1
        border = Self.nearestBorder(to: point, in: WindowLayout.slots(count: count, in: area, split: split))
    }

    /// The split with the pointer at `point`.
    func split(at point: CGPoint) -> Split {
        var split = startSplit
        split.moveDivider(by: (point.x - start.x) / area.width)
        if let border {
            split.moveRowBorder(border, of: rows, by: (point.y - start.y) / area.height)
        }
        return split
    }

    /// The border between two rows of the right column that's nearest `point`, by the row below which
    /// it lies, or nil when `point` is in the left column or there's one row. `slots` are the left
    /// column's then the rows'.
    private static func nearestBorder(to point: CGPoint, in slots: [CGRect]) -> Int? {
        let rows = slots.dropFirst()
        guard rows.count > 1, let right = rows.first, point.x >= right.minX else { return nil }
        let borders = rows.dropLast().map { abs($0.maxY - point.y) }
        return borders.indices.min { borders[$0] < borders[$1] }
    }
}
