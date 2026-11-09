/// The macOS parts of every module, which only the app builds.
@MainActor
public struct ModuleSystems {
    /// The keyboard module's.
    let keyboard: KeyboardSystem
    /// The window manager's.
    let windows: WindowManagerSystem
    /// The launcher's.
    let launcher: LauncherSystem
    /// The clipboard history's.
    let clipboard: ClipboardSystem

    /// Gathers them.
    public init(
        keyboard: KeyboardSystem, windows: WindowManagerSystem, launcher: LauncherSystem, clipboard: ClipboardSystem
    ) {
        self.keyboard = keyboard
        self.windows = windows
        self.launcher = launcher
        self.clipboard = clipboard
    }
}
