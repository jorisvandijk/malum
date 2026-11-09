import AppKit
import MalumCore

/// Tells the window manager which apps run and what happens to them, through `NSWorkspace`.
@MainActor
public final class WorkspaceAppWatcher {
    /// The workspace notifications it follows, each with the event it makes from the app it names.
    private static let events: [(Notification.Name, @Sendable (RunningApp) -> AppEvent)] = [
        (NSWorkspace.didLaunchApplicationNotification, { .launched($0) }),
        (NSWorkspace.didTerminateApplicationNotification, { .terminated($0.pid) }),
        (NSWorkspace.didActivateApplicationNotification, { .activated($0) }),
        (NSWorkspace.didUnhideApplicationNotification, { .unhidden($0.pid) }),
    ]

    /// The observers while it runs.
    private var observers: [any NSObjectProtocol] = []

    /// Creates the watcher, not yet watching.
    public init() {}

    /// The app a workspace notification names, or nil when it names none.
    private nonisolated static func app(in notification: Notification) -> RunningApp? {
        (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
            .map(WorkspaceApps.describe)
    }
}

// MARK: - AppWatcher

extension WorkspaceAppWatcher: AppWatcher {
    /// Every app that runs and isn't quitting.
    public func runningApps() -> [RunningApp] {
        NSWorkspace.shared.runningApplications.filter { !$0.isTerminated }.map(WorkspaceApps.describe)
    }

    /// Sends the workspace's launch, quit, activation and unhide notifications to `onEvent`. They
    /// arrive on the main queue.
    public func start(_ onEvent: @escaping @MainActor @Sendable (AppEvent) -> Void) {
        stop()
        let center = NSWorkspace.shared.notificationCenter
        observers = Self.events.map { name, event in
            center.addObserver(forName: name, object: nil, queue: .main) { notification in
                guard let app = Self.app(in: notification) else { return }
                let happened = event(app)
                MainActor.assumeIsolated { onEvent(happened) }
            }
        }
    }

    /// Stops following the notifications.
    public func stop() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in observers {
            center.removeObserver(observer)
        }
        observers = []
    }
}
