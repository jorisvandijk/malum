import AppKit

/// The popup's sizes, in points.
enum PopupLayout {
    /// The panel's width.
    static let width: CGFloat = 680
    /// The height of the search area at the top.
    static let searchHeight: CGFloat = 56
    /// The height of one row.
    static let rowHeight: CGFloat = 44
    /// The radius of the panel's corners.
    static let cornerRadius: CGFloat = 16
    /// The space at the left and right edges.
    static let margin: CGFloat = 18
    /// The size of the magnifying glass and the row icons.
    static let iconSize: CGFloat = 32
    /// The size of the small buttons and the detail text's height.
    static let smallSize: CGFloat = 20
    /// The width of the list's name and of a row's detail.
    static let labelWidth: CGFloat = 80
    /// The width of the clear button.
    static let buttonWidth: CGFloat = 140
    /// The search text's size.
    static let searchFontSize: CGFloat = 24
    /// A row's title size.
    static let titleFontSize: CGFloat = 15
    /// The size of the list's name and a row's detail.
    static let smallFontSize: CGFloat = 12
    /// Half a row more than the visible rows, so it shows the list scrolls.
    static let peekRows: CGFloat = 0.5
    /// The panel's top sits this far down the screen, like Spotlight.
    static let topFraction: CGFloat = 0.2
    /// How far the selection is drawn inside its row, across.
    static let selectionInsetAcross: CGFloat = 8
    /// How far the selection is drawn inside its row, down.
    static let selectionInsetDown: CGFloat = 2
    /// The radius of the selection's corners.
    static let selectionRadius: CGFloat = 8

    /// Where text starts after an icon: the margin, the icon, and the margin again.
    static let textLeft: CGFloat = 68
    /// What two halves make, for centring.
    private static let halves: CGFloat = 2

    /// How far from the top `height` sits when it's centred in `outer`.
    static func middle(of height: CGFloat, in outer: CGFloat) -> CGFloat {
        (outer - height) / halves
    }

    /// A square of `side` points.
    static func square(_ side: CGFloat) -> NSSize {
        NSSize(width: side, height: side)
    }

    /// The panel's size for `rows` visible rows.
    static func size(rows: Int) -> NSSize {
        NSSize(width: width, height: searchHeight + rowHeight * (CGFloat(rows) + peekRows))
    }

    /// The top-left corner and size in AppKit's bottom-up coordinates, as a frame inside `bounds`.
    static func frame(left: CGFloat, top: CGFloat, size: NSSize, in bounds: NSRect) -> NSRect {
        NSRect(x: left, y: bounds.height - top - size.height, width: size.width, height: size.height)
    }
}
