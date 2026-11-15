import Foundation

/// Lets the user click any window and shows what Malum sees in it, like `xprop`: app, bundle ID,
/// title, role, frame, workspace keys and what the window manager does with it. Writes nothing.
@MainActor
final class WindowInspector {
    /// Where the window under the click is found.
    private let windows: any WindowAccess
    /// Which app a window belongs to.
    private let watcher: any AppWatcher
    /// The picker, panel and clipboard.
    private let system: WindowInspectorSystem
    /// The window manager's log.
    private let log: Log
    /// Whether a click is being waited for, so a second press doesn't open a second picker.
    private var isPicking = false

    /// Creates the inspector, finding windows through `windows` and their apps through `watcher`.
    init(windows: any WindowAccess, watcher: any AppWatcher, system: WindowInspectorSystem, log: Log) {
        self.windows = windows
        self.watcher = watcher
        self.system = system
        self.log = log
    }

    /// Waits for a click on a window and shows its report. `keys` gives each app's workspace keys,
    /// and `handling` what the window manager does with the window. A click on nothing shows nothing.
    func inspect(
        keys: [String: [Hotkey]], handling: (PointedWindow, RunningApp?) -> WindowReport.Handling
    ) async {
        guard !isPicking else { return }
        isPicking = true
        let clicked = await system.picker.pick()
        isPicking = false
        guard clicked else { return }
        guard let pointed = windows.window(at: windows.pointerLocation) else {
            log.report(.noWindowThere)
            return
        }
        let app = watcher.runningApps().first { $0.pid == pointed.pid }
        let report = WindowReport(
            app: app?.name, bundleID: app?.bundleID, facts: pointed.window.facts, frame: pointed.window.frame,
            keys: app?.bundleID.flatMap { keys[$0] } ?? [], handling: handling(pointed, app))
        system.panel.show(report.lines) { [weak self] in self?.copy(report) }
    }

    /// Puts `report` on the clipboard as text.
    private func copy(_ report: WindowReport) {
        let entry = ClipEntry(id: UUID().uuidString, kind: .text, date: .now, text: report.text)
        guard !system.clipboard.put(entry, image: nil) else { return }
        log.report(.couldntCopyReport)
    }
}
