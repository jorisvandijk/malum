/// How thick a line is or how big text is, picked in the toolbar.
public enum AnnotationSize: CaseIterable, Comparable, Sendable {
    /// Thin lines and small text.
    case small
    /// The size a shot starts with.
    case medium
    /// Thick lines and big text.
    case large

    /// A line's width in points of the shot.
    public var lineWidth: Double {
        switch self {
        case .small: Self.smallLine
        case .medium: Self.mediumLine
        case .large: Self.largeLine
        }
    }

    /// Text's size in points of the shot.
    public var textSize: Double {
        switch self {
        case .small: Self.smallText
        case .medium: Self.mediumText
        case .large: Self.largeText
        }
    }

    /// The next size down, or this one when it's the smallest.
    var smaller: Self {
        switch self {
        case .small, .medium: .small
        case .large: .medium
        }
    }

    /// The next size up, or this one when it's the largest.
    var larger: Self {
        switch self {
        case .small: .medium
        case .medium, .large: .large
        }
    }

    /// Line widths, from thin to thick.
    private static let smallLine = 2.0
    private static let mediumLine = 4.0
    private static let largeLine = 8.0
    /// Text sizes, from small to big.
    private static let smallText = 16.0
    private static let mediumText = 24.0
    private static let largeText = 40.0
}
