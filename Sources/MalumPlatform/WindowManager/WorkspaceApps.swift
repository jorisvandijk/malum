import AppKit
import ApplicationServices
import MalumCore

/// Runs, raises and hides apps through `NSWorkspace`, with Accessibility where AppKit falls short.
@MainActor
public final class WorkspaceApps {
    /// Uses the shared workspace.
    public init() {}

    /// The running app with process ID `pid`, or nil when it has quit.
    private func process(_ app: RunningApp) -> NSRunningApplication? {
        NSRunningApplication(processIdentifier: app.pid).flatMap { $0.isTerminated ? nil : $0 }
    }

    /// `app` through Accessibility.
    private func element(_ app: RunningApp) -> AccessibilityElement {
        AccessibilityElement(element: AXUIElementCreateApplication(app.pid))
    }

    /// What run or raise needs to know about `app`.
    private static func describe(_ app: NSRunningApplication) -> RunningApp {
        RunningApp(
            pid: app.processIdentifier, bundleID: app.bundleIdentifier,
            name: app.localizedName ?? app.bundleIdentifier ?? String(app.processIdentifier),
            isActive: app.isActive, isHidden: app.isHidden, isRegular: app.activationPolicy == .regular)
    }
}

// MARK: - AppControl

extension WorkspaceApps: AppControl {
    /// The first running copy of the app with `bundleID` that isn't quitting.
    public func running(_ bundleID: String) -> RunningApp? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first { !$0.isTerminated }
            .map(Self.describe)
    }

    /// Every ordinary app that runs and isn't hidden or quitting.
    public func visibleApps() -> [RunningApp] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && !$0.isHidden && !$0.isTerminated }
            .map(Self.describe)
    }

    /// What `app`'s windows look like, or `.unknown` when it doesn't answer.
    public func windows(of app: RunningApp) -> AppWindowsState {
        guard let windows = element(app).elements(AccessibilityName.windows) else { return .unknown }
        guard !windows.isEmpty else { return .noWindows }
        let minimized = windows.allSatisfy {
            AccessibilityElement(element: $0).bool(AccessibilityName.minimized) ?? false
        }
        return minimized ? .onlyMinimized : .some
    }

    /// Opens the app with `bundleID` and brings it to the front. A running app is asked for a new
    /// window, as a click on its Dock icon does.
    public func open(_ bundleID: String) async throws(WindowManagerError) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            throw .notInstalled(bundleID)
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        do {
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        } catch {
            throw .openFailed(bundleID, reason: error.localizedDescription)
        }
    }

    /// Shows `app`.
    public func unhide(_ app: RunningApp) {
        process(app)?.unhide()
    }

    /// Asks macOS to bring `app` to the front, and also sets it frontmost through Accessibility, since
    /// macOS can turn down a background app's request.
    public func activate(_ app: RunningApp) {
        process(app)?.activate()
        element(app).set(AccessibilityName.frontmost, true)
    }

    /// Brings back the first minimised window, which is the most recent, since Accessibility lists
    /// windows front to back.
    public func unminimize(_ app: RunningApp) {
        let windows = element(app).elements(AccessibilityName.windows) ?? []
        guard
            let window = windows.map(AccessibilityElement.init).first(where: {
                $0.bool(AccessibilityName.minimized) ?? false
            })
        else { return }
        window.set(AccessibilityName.minimized, false)
        AXUIElementPerformAction(window.element, AccessibilityName.raise as CFString)
    }

    /// Hides `app`. `NSRunningApplication.hide()` often hides the app yet says it didn't, so then it's
    /// hidden again through Accessibility, whose answer holds. An app that quit needs no hiding.
    public func hide(_ app: RunningApp) -> Bool {
        guard let process = process(app) else { return true }
        guard !process.hide() else { return true }
        return element(app).set(AccessibilityName.hidden, true)
    }
}
