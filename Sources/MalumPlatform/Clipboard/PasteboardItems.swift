import AppKit
import MalumCore

/// Turns the pasteboard into a `Copy`, and a history entry back into pasteboard items.
@MainActor
enum PasteboardItems {
    /// What's on `pasteboard`: file paths first (Finder puts their names in as text too), then an
    /// image when there's no text, then text. Nil for anything else.
    static func copy(from pasteboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Copy? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL]
        if types.contains(.fileURL), let urls, !urls.isEmpty {
            return .files(urls.map(\.path))
        }
        let text = pasteboard.string(forType: .string)
        guard let text, !text.allSatisfy(\.isWhitespace) else {
            return png(from: pasteboard).map { .image(png: $0) }
        }
        return .text(text, rtf: pasteboard.data(forType: .rtf))
    }

    /// The pasteboard items for `entry`: text with its rich text, the image as PNG and TIFF, or
    /// the files as files (for Finder) with their paths as text (for everything else).
    static func items(for entry: ClipEntry, image: Data?) -> [NSPasteboardItem] {
        switch entry.kind {
        case .text:
            let item = NSPasteboardItem()
            item.setString(entry.text ?? "", forType: .string)
            if let rtf = entry.rtf { item.setData(rtf, forType: .rtf) }
            return [item]
        case .image:
            guard let image else { return [] }
            let item = NSPasteboardItem()
            item.setData(image, forType: .png)
            if let tiff = NSImage(data: image)?.tiffRepresentation { item.setData(tiff, forType: .tiff) }
            return [item]
        case .files:
            return fileItems(entry.paths ?? [])
        }
    }

    /// One item per file, the first also holding every path as text.
    private static func fileItems(_ paths: [String]) -> [NSPasteboardItem] {
        paths.enumerated().map { place, path in
            let item = NSPasteboardItem()
            item.setString(URL(fileURLWithPath: path).absoluteString, forType: .fileURL)
            if place == 0 { item.setString(paths.joined(separator: "\n"), forType: .string) }
            return item
        }
    }

    /// The image on `pasteboard` as PNG, turning TIFF into PNG.
    private static func png(from pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: .png) { return png }
        guard let tiff = pasteboard.data(forType: .tiff), let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
