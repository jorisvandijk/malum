import ApplicationServices
import MalumCore

/// An app whose windows are watched through an `AXObserver` on the main run loop.
@MainActor
final class AccessibilityApp {
    /// What each window is watched for.
    private static let windowNotifications = [
        AccessibilityName.destroyed, AccessibilityName.moved, AccessibilityName.resized,
        AccessibilityName.minimizedNotification, AccessibilityName.restored,
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
        guard watch(app, for: AccessibilityName.windowCreated) else { return nil }
        watch(app, for: AccessibilityName.focusedWindowChanged)
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }

    /// Takes the observer off the main run loop, so a notification never reaches an app that's gone.
    isolated deinit {
        stop()
    }

    /// Hands an `AXObserver` notification to the app it was registered for. The observer's source is
    /// on the main run loop, so this runs on the main thread.
    /// The pointer crosses into the main actor as a plain number, since a raw pointer isn't Sendable.
    private static let callback: AXObserverCallback = { _, _, notification, refcon in
        let address = UInt(bitPattern: refcon)
        let name = notification as String
        MainActor.assumeIsolated {
            guard let pointer = UnsafeMutableRawPointer(bitPattern: address) else { return }
            Unmanaged<AccessibilityApp>.fromOpaque(pointer).takeUnretainedValue().handle(name)
        }
    }

    /// Tells `onChange` what `notification` means.
    private func handle(_ notification: String) {
        let moved = [AccessibilityName.moved, AccessibilityName.resized].contains(notification)
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
        guard let elements = AccessibilityElement(element: app).elements(AccessibilityName.windows) else { return nil }
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
