/// What a running app's windows look like, as far as run or raise cares.
public enum AppWindowsState: Equatable, Sendable {
    /// Accessibility didn't answer, so the windows are left alone.
    case unknown
    /// It has no windows.
    case noWindows
    /// Every window is minimised.
    case onlyMinimized
    /// At least one window is in view.
    case some
}
