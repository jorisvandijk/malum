/// The full-screen overlay a frozen screen is cropped and drawn on.
@MainActor
public protocol ScreenshotOverlay {
    /// Shows `frozen` with `quickColors` in the toolbar until the user saves or cancels. Gives what
    /// was done to the shot on save, or nil on cancel.
    func edit(_ frozen: any FrozenScreen, quickColors: [ScreenshotColor]) async -> ScreenshotEdits?
}
