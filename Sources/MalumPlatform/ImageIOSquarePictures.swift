import CoreGraphics
import Foundation
import ImageIO
import MalumCore
import UniformTypeIdentifiers

/// Makes square pictures through ImageIO and CoreGraphics.
public struct ImageIOSquarePictures {
    /// The width and height of the square, in pixels, as big as macOS shows a user's picture.
    private static let side = 512
    /// Bits in each colour of a pixel.
    private static let bitsPerColour = 8
    /// What the space left beside the square is split by, so it's the same on both sides.
    private static let sides = 2

    /// Creates the maker.
    public init() {}
}

// MARK: - SquarePictures

extension ImageIOSquarePictures: SquarePictures {
    /// The middle square of the picture at `path`, scaled to `side`, as a PNG.
    public func squarePNG(of path: String) throws(PictureError) -> Data {
        guard
            let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
            let picture = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { throw .unreadable(path: path) }
        let length = min(picture.width, picture.height)
        let middle = CGRect(
            x: (picture.width - length) / Self.sides, y: (picture.height - length) / Self.sides, width: length,
            height: length)
        guard
            let square = picture.cropping(to: middle),
            let colours = CGColorSpace(name: CGColorSpace.sRGB),
            let canvas = CGContext(
                data: nil, width: Self.side, height: Self.side, bitsPerComponent: Self.bitsPerColour, bytesPerRow: 0,
                space: colours, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw .notMade(path: path) }
        canvas.interpolationQuality = .high
        canvas.draw(square, in: CGRect(x: 0, y: 0, width: Self.side, height: Self.side))
        let png = NSMutableData()
        guard
            let scaled = canvas.makeImage(),
            let destination = CGImageDestinationCreateWithData(png, UTType.png.identifier as CFString, 1, nil)
        else { throw .notMade(path: path) }
        CGImageDestinationAddImage(destination, scaled, nil)
        guard CGImageDestinationFinalize(destination) else { throw .notMade(path: path) }
        return png as Data
    }
}
