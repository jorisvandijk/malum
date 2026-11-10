/// A size the Mac's own screen shows things at, in points, such as 1710x1112 for System Settings'
/// "More Space" on a 13 inch MacBook Air.
public struct DisplayResolution: Equatable, Hashable, Sendable {
    /// What joins the width and the height, as `macos.toml` and messages write them.
    static let separator: Character = "x"
    /// The parts a size is written in: the width and the height.
    private static let partCount = 2

    /// How wide the screen is, in points.
    public let width: Int
    /// How high the screen is, in points.
    public let height: Int

    /// Creates the size `width` by `height` points.
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /// The size written as `<width>x<height>`, such as `1710x1112`, or nil when `text` isn't one.
    init?(_ text: String) {
        let parts = text.split(separator: Self.separator, omittingEmptySubsequences: false)
        guard parts.count == Self.partCount, let width = parts.first.flatMap({ Int($0) }),
            let height = parts.last.flatMap({ Int($0) }), width > 0, height > 0
        else { return nil }
        self.init(width: width, height: height)
    }
}

// MARK: - Comparable

extension DisplayResolution: Comparable {
    /// Narrower sizes first, then lower ones.
    public static func < (lhs: DisplayResolution, rhs: DisplayResolution) -> Bool {
        (lhs.width, lhs.height) < (rhs.width, rhs.height)
    }
}
