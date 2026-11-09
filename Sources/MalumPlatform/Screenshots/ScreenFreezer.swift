import AppKit
import MalumCore
import ScreenCaptureKit

/// Freezes the screen under the mouse through ScreenCaptureKit, which needs Screen Recording.
@MainActor
public struct ScreenFreezer: ScreenCapture {
    /// The key of an `NSScreen`'s display ID in its device description.
    private static let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")

    /// Creates the freezer.
    public init() {}

    /// Captures the screen the mouse is on at its full pixel size, without the pointer.
    public func freeze() async throws(ScreenshotError) -> any FrozenScreen {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let screen, let number = screen.deviceDescription[Self.screenNumberKey] as? NSNumber else {
            throw .noScreen
        }
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            throw .captureFailed(error.localizedDescription)
        }
        guard let display = content.displays.first(where: { $0.displayID == number.uint32Value }) else {
            throw .noScreen
        }
        let scale = screen.backingScaleFactor
        let configuration = SCStreamConfiguration()
        configuration.width = Int(screen.frame.width * scale)
        configuration.height = Int(screen.frame.height * scale)
        configuration.showsCursor = false
        let filter = SCContentFilter(display: display, excludingWindows: [])
        do {
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            return CapturedScreen(image: image, frame: screen.frame, scale: scale)
        } catch {
            throw .captureFailed(error.localizedDescription)
        }
    }
}
