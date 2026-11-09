import ApplicationServices
import MalumCore

/// An app whose windows are watched through an `AXObserver` on the main run loop.
@MainActor
final class AccessibilityApp {
    /// What the app tells about its windows, written out because the framework's constants aren't
    /// safe to read under strict concurrency.
    private enum Notification {
        static let windowCreated = "AXWindowCreated"
        static let focusedWindowChanged = "AXFocusedWindowChanged"
        static let destroyed = "AXUIElementDestroyed"
        static let moved = "AXWindowMoved"
        static let resized = "AXWindowResized"
        static let minimized = "AXWindowMiniaturized"
        static let restored = "AXWindowDeminiaturized"
    }

    /// The app's attribute that lists its windows.
    private static let windowsAttribute = "AXWindows"
    /// What each window is watched for.
    private static let windowNotifications = [
        Notification.destroyed, Notification.moved, Notification.resized, Notification.minimized, Notification.restored,
    ]

    /// The app.
    private let app: AXUIElement
    /// Calls back on the main run loop.
    private let observer: AXObserver
    /// Told what happened.
    private let onChange: @MainActor (WindowEvent) -> Void

    /// Starts watching the app with process ID `pid`, or gives nil when it doesn't answer yet.
    init?(pid: Int32, onChange: @escaping @MainActor (WindowEvent) -> Void) {
        var created: AXObserver?
        guard AXObserverCreate(pid, Self.callback, &created) == .success, let created else { return nil }
        app = AXUIElementCreateApplication(pid)
        observer = created
        self.onChange = onChange
        guard watch(app, for: Notification.windowCreated) else { return nil }
        watch(app, for: Notification.focusedWindowChanged)
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }

    /// Takes the observer off the main run loop, so a notification never reaches an app that's gone.
    isolated deinit {
        stop()
    }

    /// Hands an `AXObserver` notification to the app it was registered for. The observer's source is
    /// on the main run loop, so this runs on the main thread.
    private static let callback: AXObserverCallback = { _, _, notification, refcon in
        guard let refcon else { return }
        let name = notification as String
        MainActor.assumeIsolated {
            Unmanaged<AccessibilityApp>.fromOpaque(refcon).takeUnretainedValue().handle(name)
        }
    }

    /// Tells `onChange` what `notification` means.
    private func handle(_ notification: String) {
        let moved = [Notification.moved, Notification.resized].contains(notification)
        onChange(moved ? .moved : .changed)
    }

    /// Asks the observer for `notification` from `element`, and says whether it's registered.
    @discardableResult
    private func watch(_ element: AXUIElement, for notification: String) -> Bool {
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        let result = AXObserverAddNotification(observer, element, notification as CFString, refcon)
        return result == .success || result == .notificationAlreadyRegistered
    }
}

// MARK: - WatchedApp

extension AccessibilityApp: WatchedApp {
    /// The app's windows, front to back, each watched from now on.
    func windows() -> [any AppWindow]? {
        guard let elements = AccessibilityElement(element: app).elements(Self.windowsAttribute) else { return nil }
        for element in elements {
            for notification in Self.windowNotifications {
                watch(element, for: notification)
            }
        }
        return elements.map { AccessibilityWindow($0, of: app) }
    }

    /// Takes the observer off the main run loop, so no more notifications arrive.
    func stop() {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }
}
