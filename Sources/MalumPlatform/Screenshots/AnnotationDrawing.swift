import AppKit
import CoreGraphics
import MalumCore

/// Draws annotations into a context whose y grows down, in the shot's points. The overlay and the
/// saved file both draw through it, so what's saved looks like what was drawn.
@MainActor
public enum AnnotationDrawing {
    /// The weight of annotation text, bold enough to read on any screen.
    private static let textWeight = NSFont.Weight.semibold

    /// Draws `annotations` in order into `context`.
    public static func draw(_ annotations: [Annotation], in context: CGContext) {
        for annotation in annotations {
            draw(annotation, in: context)
        }
    }

    /// Draws one annotation.
    private static func draw(_ annotation: Annotation, in context: CGContext) {
        let color = annotation.color.cgColor
        let width = annotation.size.lineWidth
        context.saveGState()
        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        switch annotation.shape {
        case .line(let start, let end):
            context.strokeLineSegments(between: [start, end])
        case .arrow(let start, let end):
            context.strokeLineSegments(between: [start, end])
            context.addLines(between: ArrowHead.corners(from: start, to: end, lineWidth: width))
            context.closePath()
            context.fillPath()
        case .rectangle(let rect):
            context.stroke(rect)
        case .text(let text, let origin):
            drawText(text, at: origin, annotation: annotation, in: context)
        }
        context.restoreGState()
    }

    /// Draws `text` with its first line's top-left corner at `origin`.
    private static func drawText(_ text: String, at origin: CGPoint, annotation: Annotation, in context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: annotation.size.textSize, weight: textWeight),
            .foregroundColor: NSColor(cgColor: annotation.color.cgColor) ?? NSColor.red,
        ]
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        NSAttributedString(string: text, attributes: attributes).draw(at: origin)
        NSGraphicsContext.restoreGraphicsState()
    }
}

extension ScreenshotColor {
    /// The color `color` is in sRGB, or nil when it has no such form, such as a pattern.
    init?(_ color: NSColor) {
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        func channel(_ value: CGFloat) -> UInt8 {
            UInt8((min(max(value, 0), 1) * Double(UInt8.max)).rounded())
        }
        self.init(red: channel(rgb.redComponent), green: channel(rgb.greenComponent), blue: channel(rgb.blueComponent))
    }

    /// The color as Core Graphics draws it.
    var cgColor: CGColor {
        CGColor(
            srgbRed: Double(red) / Double(UInt8.max), green: Double(green) / Double(UInt8.max),
            blue: Double(blue) / Double(UInt8.max), alpha: 1)
    }
}
