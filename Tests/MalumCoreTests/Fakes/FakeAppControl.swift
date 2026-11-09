@testable import MalumCore

/// Apps that only exist in the test: writes down every call, and fails what it's told to.
@MainActor
final class FakeAppControl: AppControl {
    /// The running apps, by bundle ID.
    var running: [String: RunningApp] = [:]
    /// What each app's windows look like, by process ID.
    var windows: [Int32: AppWindowsState] = [:]
    /// The apps `hide` fails for, by process ID.
    var refusesToHide: Set<Int32> = []
    /// What `open` throws, or nil when it works.
    var openError: WindowManagerError?
    /// Every call, in order, such as `open com.apple.finder` or `hide Finder`.
    private(set) var calls: [String] = []

    func running(_ bundleID: String) -> RunningApp? {
        running[bundleID]
    }

    func visibleApps() -> [RunningApp] {
        running.values.filter { $0.isRegular && !$0.isHidden }.sorted { $0.pid < $1.pid }
    }

    func windows(of app: RunningApp) -> AppWindowsState {
        windows[app.pid] ?? .unknown
    }

    func open(_ bundleID: String) async throws(WindowManagerError) {
        calls.append("open \(bundleID)")
        if let openError {
            throw openError
        }
    }

    func unhide(_ app: RunningApp) {
        calls.append("unhide \(app.name)")
    }

    func activate(_ app: RunningApp) {
        calls.append("activate \(app.name)")
    }

    func unminimize(_ app: RunningApp) {
        calls.append("unminimize \(app.name)")
    }

    func hide(_ app: RunningApp) -> Bool {
        calls.append("hide \(app.name)")
        return !refusesToHide.contains(app.pid)
    }
}
