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
    private static let sides = 2.0

    /// Creates the maker.
    public init() {}
}

// MARK: - SquarePictures

extension ImageIOSquarePictures: SquarePictures {
    /// The part `crop` of the picture at `path`, or its middle square, scaled to `side`, as a JPEG.
    public func squareJPEG(of path: String, crop: PictureCrop?) throws(PictureError) -> Data {
        guard
            let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
            let picture = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { throw .unreadable(path: path) }
        guard
            let square = picture.cropping(to: area(crop, of: picture)),
            let colours = CGColorSpace(name: CGColorSpace.sRGB),
            let canvas = CGContext(
                data: nil, width: Self.side, height: Self.side, bitsPerComponent: Self.bitsPerColour, bytesPerRow: 0,
                space: colours, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { throw .notMade(path: path) }
        canvas.interpolationQuality = .high
        canvas.draw(square, in: CGRect(x: 0, y: 0, width: Self.side, height: Self.side))
        let jpeg = NSMutableData()
        guard
            let scaled = canvas.makeImage(),
            let destination = CGImageDestinationCreateWithData(
                jpeg as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw .notMade(path: path) }
        CGImageDestinationAddImage(destination, scaled, nil)
        guard CGImageDestinationFinalize(destination) else { throw .notMade(path: path) }
        return jpeg as Data
    }

    /// The area of `picture` to keep, measured from its top-left corner as CoreGraphics crops:
    /// `crop`, which is measured from the bottom-left, or the middle square.
    private func area(_ crop: PictureCrop?, of picture: CGImage) -> CGRect {
        let width = Double(picture.width)
        let height = Double(picture.height)
        guard let crop else {
            let length = min(width, height)
            return CGRect(
                x: (width - length) / Self.sides, y: (height - length) / Self.sides, width: length, height: length)
        }
        return CGRect(x: crop.left, y: height - crop.bottom - crop.height, width: crop.width, height: crop.height)
    }
}
