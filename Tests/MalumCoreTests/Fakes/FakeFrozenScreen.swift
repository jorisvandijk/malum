import Foundation

@testable import MalumCore

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// A frozen screen whose PNG is text naming the crop and how many annotations it has.
@MainActor
final class FakeFrozenScreen: FrozenScreen {
    let screen = CGRect(x: 0, y: 0, width: 1000, height: 600)
    /// Whether making the PNG fails.
    var unencodable = false

    func png(crop: CGRect, annotations: [Annotation]) throws(ScreenshotError) -> Data {
        guard !unencodable else { throw .unencodable }
        return Data("\(Int(crop.width))x\(Int(crop.height)) with \(annotations.count)".utf8)
    }

    #if canImport(CoreGraphics)
        var image: CGImage {
            let space = CGColorSpaceCreateDeviceRGB()
            let info = CGImageAlphaInfo.premultipliedLast.rawValue
            let context = CGContext(
                data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info)
            guard let image = context?.makeImage() else { preconditionFailure("no image") }
            return image
        }
        var frame: CGRect { screen }
    #endif
}
