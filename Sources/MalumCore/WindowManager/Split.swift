import Foundation

// Linux's Foundation has the geometry types; on macOS they come from CoreGraphics.
#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// How an app's area is shared out between its windows: the left column's share of the width, and
/// from three windows on, each row's share of the right column's height. Shares are fractions of
/// the area, so a step of 0.05 moves a border by 5% of its width or height.
struct Split: Equatable, Sendable {
    /// The smallest share the left column, the right column or a row gets.
    static let minimum: CGFloat = 0.2
    /// The left column's share when nothing has moved it: half.
    static let even: CGFloat = 0.5
    /// Shares are rounded to this, so moving a border back and forth lands where it started.
    private static let precision: CGFloat = 10_000

    /// The left column's share of the area's width.
    private(set) var left = even
    /// Each row's share of the right column's height, top first, or nil when they're equal.
    private(set) var rows: [CGFloat]?

    /// Each of `count` rows' share of the right column's height, top first. Rows that were set for
    /// another number of windows are shared out equally again.
    func rowShares(count: Int) -> [CGFloat]? {
        guard let rows, rows.count == count else { return nil }
        return rows
    }

    /// Moves the border between the left column and the right one by `step` of the area's width,
    /// right when it's positive, keeping both columns at least `minimum` wide.
    mutating func moveDivider(by step: CGFloat) {
        left = Self.rounded(min(max(left + step, Self.minimum), 1 - Self.minimum))
    }

    /// Makes row `index` of `count` rows taller by `step` of the right column's height, or shorter
    /// when it's negative. A taller row takes from the others by what each has to spare, a shorter one
    /// gives to the others equally, and no row gets less than `floor(count:)`.
    mutating func resizeRow(_ index: Int, of count: Int, by step: CGFloat) {
        guard count > 1, (0..<count).contains(index) else { return }
        var shares = rowShares(count: count) ?? Array(repeating: 1 / CGFloat(count), count: count)
        let floor = Self.floor(count: count)
        let others = shares.indices.filter { $0 != index }
        let spare = others.reduce(0) { $0 + max(shares[$1] - floor, 0) }
        let change = min(max(step, floor - shares[index]), spare)
        guard change != 0 else { return }
        for other in others {
            let give = change > 0 ? change * max(shares[other] - floor, 0) / spare : change / CGFloat(others.count)
            shares[other] = Self.rounded(shares[other] - give)
        }
        shares[index] = Self.rounded(1 - others.reduce(0) { $0 + shares[$1] })
        rows = shares
    }

    /// The smallest share a row of `count` gets: `minimum`, or half an equal share when there are
    /// so many rows that `minimum` would leave nothing to move.
    static func floor(count: Int) -> CGFloat {
        min(minimum, even / CGFloat(count))
    }

    /// `share` rounded to `precision`.
    private static func rounded(_ share: CGFloat) -> CGFloat {
        (share * precision).rounded() / precision
    }
}
