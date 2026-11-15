import AppKit
import MalumCore

/// The real window picker: a faint overlay on every screen that takes one click, with a hint on the
/// screen with the menu bar and a crosshair pointer. Esc cancels.
@MainActor
public final class ClickPicker: WindowPicker {
    /// How dark the overlay makes the screens, so it's clear a click is awaited.
    private static let tintAlpha = 0.08
    /// How long to wait after the overlay is gone before saying so, so Accessibility finds the window
    /// below it and not the overlay.
    private static let settleMilliseconds = 50

    /// The overlays while a click is awaited.
    private var windows: [OverlayWindow] = []
    /// Hands the answer back to the caller of `pick`.
    private var finish: CheckedContinuation<Bool, Never>?

    /// Creates the picker, closed.
    public init() {}

    /// Covers every screen and waits for a click or esc. A pick that's still open is cancelled.
    public func pick() async -> Bool {
        close(clicked: false)
        windows = NSScreen.screens.enumerated().map { index, screen in
            cover(screen, withHint: index == 0)
        }
        for window in windows.reversed() {
            window.makeKeyAndOrderFront(nil)
        }
        NSCursor.crosshair.push()
        let clicked = await withCheckedContinuation { finish = $0 }
        try? await Task.sleep(for: .milliseconds(Self.settleMilliseconds))  // Cancelled only shortens it.
        return clicked
    }

    /// An overlay over `screen`, with the hint when `withHint`.
    private func cover(_ screen: NSScreen, withHint: Bool) -> OverlayWindow {
        let window = OverlayWindow(frame: screen.frame, tint: .black.withAlphaComponent(Self.tintAlpha))
        let view = ClickView(frame: CGRect(origin: .zero, size: screen.frame.size), showsHint: withHint)
        view.onAnswer = { [weak self] clicked in self?.close(clicked: clicked) }
        window.contentView = view
        window.initialFirstResponder = view
        return window
    }

    /// Takes the overlays away and hands `clicked` back.
    private func close(clicked: Bool) {
        guard !windows.isEmpty else { return }
        NSCursor.pop()
        for window in windows {
            window.orderOut(nil)
        }
        windows = []
        finish?.resume(returning: clicked)
        finish = nil
    }
}
