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

    /// The state of an app whose Accessibility windows have these roles and minimised flags. Only real
    /// windows count, so Finder's desktop, which Accessibility lists as a scroll area among its windows,
    /// doesn't keep Finder from opening one. A window that doesn't say its role yet counts.
    public init(windows: [(role: String?, isMinimized: Bool)]) {
        let real = windows.filter { ($0.role ?? WindowLayout.windowRole) == WindowLayout.windowRole }
        guard !real.isEmpty else {
            self = .noWindows
            return
        }
        self = real.allSatisfy { $0.isMinimized } ? .onlyMinimized : .some
    }
}
