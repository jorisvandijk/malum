import AppKit
import MalumCore

/// The real screenshot overlay: an `OverlayWindow` over the frozen screen with an `OverlayView`,
/// and macOS's color picker when the toolbar asks for it.
@MainActor
public final class FullScreenOverlay: NSObject, ScreenshotOverlay {
    /// Puts the color picker above the overlay, which sits at the screen saver's level.
    private static let pickerLevel = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)

    /// The open overlay, if any.
    private var window: OverlayWindow?
    /// The open overlay's view, which holds the session.
    private var view: OverlayView?
    /// Hands the result back to the caller of `edit`.
    private var finish: CheckedContinuation<ScreenshotEdits?, Never>?

    /// Creates the overlay, closed.
    override public init() {
        super.init()
    }

    /// Covers the frozen screen and waits for save or cancel. An overlay that's still open is
    /// cancelled first.
    public func edit(_ frozen: any FrozenScreen, quickColors: [ScreenshotColor]) async -> ScreenshotEdits? {
        close(with: nil)
        let view = OverlayView(
            frozen: frozen, session: ScreenshotSession(screen: frozen.screen, quickColors: quickColors))
        let window = OverlayWindow(frame: frozen.frame)
        window.contentView = view
        view.onOutcome = { [weak self] outcome in self?.handle(outcome) }
        self.window = window
        self.view = view
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        return await withCheckedContinuation { finish = $0 }
    }

    /// Carries out what the view hands on.
    private func handle(_ outcome: ScreenshotSession.Outcome) {
        switch outcome {
        case .save:
            close(with: view?.session.edits)
        case .cancel:
            close(with: nil)
        case .openColorPicker:
            openColorPicker()
        case .unchanged, .redraw:
            return
        }
    }

    /// Shows macOS's color picker above the overlay, sending picked colors to `picked`.
    private func openColorPicker() {
        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(picked(_:)))
        panel.level = Self.pickerLevel
        panel.orderFrontRegardless()
    }

    /// Takes the color picker's color for what's drawn next.
    @objc private func picked(_ panel: NSColorPanel) {
        guard let view, let color = ScreenshotColor(panel.color) else { return }
        view.pick(color)
    }

    /// Closes the overlay and the picker, and hands `edits` back.
    private func close(with edits: ScreenshotEdits?) {
        NSColorPanel.shared.setTarget(nil)
        NSColorPanel.shared.orderOut(nil)
        window?.orderOut(nil)
        window = nil
        view = nil
        finish?.resume(returning: edits)
        finish = nil
    }
}
