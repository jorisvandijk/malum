import CoreGraphics
import MalumCore

/// The Mac's own screen, through CoreGraphics' display modes: the sizes System Settings offers
/// under Displays, each a mode of the screen.
@MainActor
public struct BuiltInDisplay {
    /// Creates the display.
    public init() {}

    /// The id of the Mac's own screen, nil when it's off, such as with the lid closed.
    private func builtInScreen() -> CGDirectDisplayID? {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success else { return nil }
        var screens = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &screens, &count) == .success else { return nil }
        return screens.first { CGDisplayIsBuiltin($0) != 0 }
    }

    /// Every mode `screen` can show the desktop in, the sharp (Retina) ones that share a size with
    /// a blurry one included.
    private func modes(of screen: CGDirectDisplayID) -> [CGDisplayMode] {
        let options = [kCGDisplayShowDuplicateLowResolutionModes as String: true] as CFDictionary
        guard let modes = CGDisplayCopyAllDisplayModes(screen, options) as? [CGDisplayMode] else { return [] }
        return modes.filter { $0.isUsableForDesktopGUI() }
    }

    /// The mode in `modes` that shows `resolution` best: a sharp one first, then one at the refresh
    /// rate of `now`, then the one with the most pixels.
    private func best(
        _ resolution: DisplayResolution, in modes: [CGDisplayMode], now: CGDisplayMode?
    ) -> CGDisplayMode? {
        let matching = modes.filter { size(of: $0) == resolution }
        let sharp = matching.filter { $0.pixelWidth > $0.width }
        let pool = sharp.isEmpty ? matching : sharp
        return pool.first { $0.refreshRate == now?.refreshRate } ?? pool.max { $0.pixelWidth < $1.pixelWidth }
    }

    /// The size `mode` shows things at.
    private func size(of mode: CGDisplayMode) -> DisplayResolution {
        DisplayResolution(width: mode.width, height: mode.height)
    }

    /// Switches `screen` to `mode` and keeps it after a restart.
    private func switchMode(of screen: CGDirectDisplayID, to mode: CGDisplayMode) throws {
        var change: CGDisplayConfigRef?
        let began = CGBeginDisplayConfiguration(&change)
        guard began == .success, let change else { throw DisplayError.refused(code: began.rawValue) }
        let configured = CGConfigureDisplayWithDisplayMode(change, screen, mode, nil)
        guard configured == .success else {
            CGCancelDisplayConfiguration(change)
            throw DisplayError.refused(code: configured.rawValue)
        }
        let completed = CGCompleteDisplayConfiguration(change, .permanently)
        guard completed == .success else { throw DisplayError.refused(code: completed.rawValue) }
    }
}

// MARK: - Display

extension BuiltInDisplay: Display {
    /// The size the screen shows things at now, nil when it's off, such as with the lid closed.
    public func resolution() -> DisplayResolution? {
        guard let screen = builtInScreen(), let mode = CGDisplayCopyDisplayMode(screen) else { return nil }
        return size(of: mode)
    }

    /// Shows the screen at `resolution` from now on, after a restart too.
    public func show(_ resolution: DisplayResolution) throws {
        guard let screen = builtInScreen() else { throw DisplayError.noScreen }
        let usable = modes(of: screen)
        guard let mode = best(resolution, in: usable, now: CGDisplayCopyDisplayMode(screen)) else {
            throw DisplayError.unavailable(resolution, offered: Set(usable.map(size)).sorted())
        }
        try switchMode(of: screen, to: mode)
    }
}
