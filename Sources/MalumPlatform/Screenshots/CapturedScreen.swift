import AppKit
import CoreGraphics
import ImageIO
import MalumCore

/// A frozen screen's pixels, with where the screen sits so the overlay can cover it.
@MainActor
public final class CapturedScreen: FrozenScreen {
    /// The type identifier of PNG.
    private static let pngType = "public.png" as CFString
    /// Bits in each color channel of a rendered shot.
    private static let bitsPerComponent = 8

    /// The frozen screen's pixels.
    public let image: CGImage
    /// Where the screen is, in AppKit's coordinates.
    public let frame: CGRect
    /// How many pixels one point takes.
    public let scale: Double

    /// Creates a frozen screen from its pixels, its frame and its scale.
    init(image: CGImage, frame: CGRect, scale: Double) {
        self.image = image
        self.frame = frame
        self.scale = scale
    }

    /// The screen in points, top-left at zero.
    public var screen: CGRect { CGRect(origin: .zero, size: frame.size) }

    /// The part `crop` as PNG at full pixel size, with `annotations` drawn on it.
    public func png(crop: CGRect, annotations: [Annotation]) throws(ScreenshotError) -> Data {
        let pixels = CGRect(
            x: crop.minX * scale, y: crop.minY * scale, width: crop.width * scale, height: crop.height * scale)
        guard let cropped = image.cropping(to: pixels.integral) else { throw .unencodable }
        let shot = annotations.isEmpty ? cropped : try drawn(annotations, on: cropped, crop: crop)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, Self.pngType, 1, nil) else { throw .unencodable }
        CGImageDestinationAddImage(destination, shot, nil)
        guard CGImageDestinationFinalize(destination) else { throw .unencodable }
        return data as Data
    }

    /// `cropped`, the part `crop` of the screen, with `annotations` drawn on it.
    private func drawn(_ annotations: [Annotation], on cropped: CGImage, crop: CGRect) throws(ScreenshotError)
        -> CGImage
    {
        let space = cropped.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)
        guard let space,
            let context = CGContext(
                data: nil, width: cropped.width, height: cropped.height, bitsPerComponent: Self.bitsPerComponent,
                bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw .unencodable }
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: cropped.width, height: cropped.height))
        context.translateBy(x: 0, y: CGFloat(cropped.height))
        context.scaleBy(x: scale, y: -scale)
        context.translateBy(x: -crop.minX, y: -crop.minY)
        AnnotationDrawing.draw(annotations, in: context)
        guard let image = context.makeImage() else { throw .unencodable }
        return image
    }
}
